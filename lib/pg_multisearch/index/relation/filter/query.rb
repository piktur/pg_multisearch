# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    class Filter::Query
      include ::PgMultisearch.adapter

      QUERY_ALIAS = ast.sql('q'.freeze).freeze

      attr_reader :strategies

      # @param [Strategies::Strategy] strategies
      def initialize(strategies)
        @strategies = Array(strategies)
      end

      # @return [void]
      def apply(*)
        @expression = expression
      end

      # @return [ast.Node] The normalized query input
      def expression # rubocop:disable AbcSize
        ast.nodes.select.tap do |obj|
          strategies.each do |strategy|
            strategy.query_cte_table = table

            obj.projections << ast.nodes.as(
              # @todo Use copy_tsquery to recycle the parsed query text if tsearch == dmetaphone
              #   options.
              # copy_tsquery(strategy) || strategy.query
              strategy.query,
              ast.sql(strategy.strategy_name.to_s)
            )
          end
        end
      end

      # @return [ast.SqlLiteral]
      def table_alias
        QUERY_ALIAS
      end

      # @return [ast.Table]
      def table
        @table ||= ast.table(QUERY_ALIAS)
      end

      private

        def primary
          strategies[0]
        end

        def secondary
          strategies[1]
        end

        def copy_tsquery(strategy)
          return unless primary.strategy_name == :tsearch &&
                        strategy.strategy_name == :dmetaphone # &&
                        # primary.options == strategy.options

          strategy.instance_variable_set(:@tsquery_builder, primary.tsquery_builder)
          strategy.query
        end
    end
  end
end
