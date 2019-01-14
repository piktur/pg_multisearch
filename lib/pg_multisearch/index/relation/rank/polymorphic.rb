# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    class Rank::Polymorphic < Rank::Base
      # @!attribute [r] default
      #   @return [Strategies::Strategy] The default ranking algorithm
      attr_reader :default

      # @param (see Rank#initialize)
      #
      # @option [Hash{[String,]=>[Symbol,]}] options :polymorphic
      def initialize(relation, *, polymorphic:, **options)
        super(relation, nil, options) do
          @strategies = {}

          polymorphic.each do |types, strategy_names|
            strategies[types] = build_strategies(strategy_names, relation)
          end

          @default = strategies.delete(:default)[0]
        end
      end

      # @return [void]
      def apply(*)
        projections << rank(&calc).as(RANK_ALIAS)
      end

      # @return [ast.Node]
      def rank(&block)
        ast.nodes.case(
          strategies.map do |types, strategies|
            [
              searchable_type?(types),
              # @todo Ensure appropriate normalization applied to ts_rank;
              #   scores must be within 0.0..1.0
              # @see https://stats.stackexchange.com/questions/281162/scale-a-number-between-a-range
              super(*strategies, polymorphic: true, &block)
            ]
          end,
          nil,
          default_rank
        )
      end

      # @return [ast.Node]
      def default_rank
        default.rank(polymorphic: true)
      end

      # @return [Projections]
      def projections
        @projections ||= Projections.new(
          source_table,
          *columns_referenced_by_strategies
        )
      end

      # @return [Array<ast.Node>]
      def columns_referenced_by_strategies
        strategies.values.flatten.map(&:projections).flatten
      end

      # @return [ast.Node]
      # def constraints
      #   @constraints ||= strategies
      #     .values
      #     .flatten
      #     .map(&:constraints)
      #     .reject(&:nil?)
      #     .reduce(&:or)
      # end

      # @return [ast.Node]
      def union
        ast.nodes.table_alias(
          strategies.map { |types, (primary, _)| rank(types, primary) }.reduce(&:union),
          RANK_ALIAS
        )
      end

      def inspect
        fn = case calc
        when ::Method then calc.name
        when ::Proc   then 'fn'
        end

        alg = strategies.map do |k, v|
          "(t in (#{k * ','.freeze}) then (#{v.map(&:strategy_name).join(', ')} -> #{fn})"
        end

        "#{alg.join(' or '.freeze)} else (#{default.strategy_name})"
      end

      protected

        # @return [Array<String>] A list of constrained types
        def constrained
          @constrained ||= strategies.keys.flatten.tap { |arr| arr.delete(:default) }
        end

        # @param [Array] types A list of constrained types
        #
        # @return [ast.Node]
        # @return [ast.Node] if `other == :default`
        # @return [ast.Node] if `other` is an `Array`
        def searchable_type?(other)
          ast.nodes.send(
            (other == :default && :not_in) || (other.is_a?(::Array) ? :in : :eq),
            searchable_type_column,
            other
          )
        end

        # @return [ast.Attribute]
        def searchable_type_column
          @searchable_type_column ||= source_table[index.projection(:searchable_type)]
        end
    end
  end
end
