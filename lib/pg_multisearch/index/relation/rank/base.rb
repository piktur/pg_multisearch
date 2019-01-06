# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    class Rank::Base
      include ::PgMultisearch.adapter

      # @return [ast.SqlLiteral]
      RANK_COLUMN = ast.sql('rank'.freeze).freeze
      private_constant :RANK_COLUMN

      # @return [ast.SqlLiteral]
      RANK_ALIAS = ast.sql('pg_multisearch_rank'.freeze).freeze

      # @!attribute [r] index
      #   @return [Index::Base]
      attr_reader :index

      # @!attribute [r] source_table
      #   @return [ast.Table]
      attr_reader :source_table

      # @!attribute [r] config
      #   @return [Configuration]
      attr_reader :config

      # @!attribute [r] strategies
      #   @return [Array<Strategies::Strategy>]
      attr_reader :strategies

      # @!attribute [r] calc
      #   @yieldparam [ast.Node] left
      #   @yieldparam [ast.Node] right
      #   @yieldreturn [ast.Node]
      #
      #   @return [Symbol, Proc]
      attr_reader :calc

      # @!attribute [r] constraints
      #   @return [Array<ast.Node>]
      attr_reader :constraints

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
      def initialize(relation, strategies, calc: ast.math.method(:avg), **)
        @config  = relation.config
        @index   = relation.scope.klass
        @calc    = calc

        @sources = [] << (@source_table = relation.filter_cte_table)

        if block_given?
          yield
        else
          @strategies = build_strategies(strategies, relation)
        end
      end

      # @return [Array<#projections, #constraints>]
      def call(*args)
        apply(*args)

        self
      end

      # @return [void]
      def apply(*)
        projections << rank(&calc).as(RANK_ALIAS)
      end

      # @return [ast.Node]
      def rank(primary = self.primary, secondary = self.secondary, **options)
        primary = primary.rank(options)

        if block_given?
          if secondary
            yield(primary, secondary.rank(options))
          else
            yield(primary)
          end
        else
          # @todo handle secondary strategy
          primary
        end
      end

      # @return [Strategies::Strategy]
      def primary
        strategies[0]
      end

      # @return [Strategies::Strategy]
      def secondary
        strategies[1]
      end

      # @return [Projections]
      def projections
        @projections ||= Projections.new(
          source_table,
          *strategies.flat_map(&:projections)
        )
      end

      # @return [ast.Node]
      # def constraints
      #   @constraints ||= strategies
      #     .map(&:constraints)
      #     .reject(&:nil?)
      #     .reduce(&:or)
      # end

      def inspect
        # "#<#{self.class} [#{strategies.map(&:strategy_name).join(',')}]>"
        "(#{strategies.map(&:strategy_name).join(',')})"
      end

      private

        def build_strategies(strategies, relation)
          Strategies.call(
            strategies,
            relation.config,
            relation.input,
            source_table,
            bind_params
          ) { |strategy| strategy.query_cte_table = relation.query_cte_table }
        end
    end
  end
end
