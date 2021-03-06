# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    class Filter::Base
      include ::PgMultisearch.adapter

      # @!attribute [r] index
      #   @return [Index::Base]
      attr_reader :index

      # @!attribute [r] scope
      #   @return [ActiveRecord::Relation]
      attr_reader :scope

      # @!attribute [r] strategies
      #   @return [Array<Strategies::Strategy>]
      attr_reader :strategies

      # @!attribute [r] sources
      #   @return [Array<ast.Node>]
      attr_reader :sources

      # @!attribute [r] references
      #   @return [Array<ast.SqlLiteral>]
      def references
        @references ||= []
      end

      # @param [Relation] relation
      # @param [Array<Symbol>] strategies
      def initialize(relation, strategies)
        @index      = relation.index
        @scope      = relation.scope
        @strategies = build_strategies(strategies, relation)
        @sources    = []
      end

      # @param [Hash] options
      #
      # @option [String] options :type
      #
      # @return [self]
      def call(options)
        apply(options)

        self
      end

      # @param (see #call)
      #
      # @yieldparam [self] filter Yields self to the block
      #
      # @return [void]
      def apply(type: nil, **options)
        yield(self) if block_given?

        sources.replace([query.table_alias, source_table] | sources)
        references.replace([query.table_alias, table_alias] | references)

        by_type(type) if type

        query.apply(options)

        @expression = expression
      end

      # @return [ast.Nodes]
      def expression
        ast.nodes.select.tap do |obj|
          obj.projections = projections.to_a
          obj.froms       = sources
          obj.wheres      = constraints
        end
      end

      # @param [Array] other
      #
      # @return [Projections]
      def projections
        @projections ||= Projections.new(
          source_table,
          *columns_referenced_by_strategies
        )
      end

      # @return [Array<ast.Node>]
      def columns_referenced_by_strategies
        strategies.flat_map(&:projections)
      end

      # @return [Array<ast.Node>]
      def constraints
        @constraints ||= [
          strategies
            .reject(&:rank_only?)
            .map(&:constraints)
            .reject(&:nil?)
            .reduce(&:or)
        ]
      end

      # @return [Query]
      def query
        @query ||= Filter::Query.new(strategies)
      end

      # @return [Strategies::Strategy]
      def primary
        strategies[0]
      end

      # @return [Strategies::Strategy]
      def secondary
        strategies[1]
      end

      # @return [Strategies::Strategy]
      def tertiary
        strategies[2]
      end

      # @return [ast.Node]
      def highlight
        primary.highlight(table)
      end

      # @return [Boolean]
      def highlight?
        primary.strategy_name == :tsearch && primary.highlight?
      end

      # @param [Type, String]
      #
      # @return [void]
      def by_type(type) # rubocop:disable AbcSize
        type = case type
        when ::String, Type
          bind(:searchable_type, type.to_s)
        when ::Array
          type.map.with_index { |t, i| bind("searchable_type#{i}".to_sym, t.to_s) }
        else
          return
        end

        projections << searchable_type
        # @todo Terrible idea to add n bind params according to input; defeats the point of
        #   prepared statements. Ideally I'd express this as `searchable_type = ANY($1)` or
        #   `searchable_type = ANY('{Organisation,Move}')` however Rails isn't able to cast and
        #   quote an Array to a Postgres Array. Postgres won't accept, nor should it, the Array
        #   body as text either. Must we compromise Postgres for Rails sake. Defiantly NO!
        constraints.replace([searchable_type.in(type)] | constraints)
      end

      # @return [ast.Attribute]
      def searchable_type
        @searchable_type ||= projections.qualified(index.projection(:searchable_type))
      end

      # @return [ast.Table]
      def table
        @table ||= ast.table(table_alias)
      end

      # @return [ast.Table]
      def source_table
        @source_table ||= ast.table(index.table_name, index) # scope.arel_table
      end

      # @return [ast.SqlLiteral]
      def table_alias
        @table_alias ||= ast.sql(scope.pg_multisearch_table_alias(:include_counter))
      end

      def inspect
        # :0x#{'%x' % (__id__ << 1)}
        # "#<#{self.class} [#{strategies.map(&:strategy_name).join(',')}]>"
        s = ' or '.freeze
        "(#{strategies.map(&:strategy_name) * s})"
      end

      private

        def build_strategies(strategies, relation)
          Strategies.call(
            strategies,
            relation.config,
            relation.input,
            source_table,
            bind_params
          ) do |strategy|
            query.strategies << strategy
            strategy.query_cte_table = query.table
          end
        end
    end
  end
end
