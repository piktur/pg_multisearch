# frozen_string_literal: true

module PgMultisearch
  module Strategies
    class Dmetaphone < Tsearch
      def self.strategy_name
        :dmetaphone
      end

      private

        def bind(value)
          super(value, :tsquery)
        end

        # @param [String] input
        #
        # @todo
        #   {Filter::Query#copy_tsquery}
        #   Querytext COULD BE recycled when dmetaphone used in conjunction with tsearch and
        #   strategy configuration matches.
        #
        # @return [ast.Node]
        def to_tsquery(input)
          ast.fn.dmetaphone_to_tsquery(
            ast.fn.string_to_dmetaphone(
              normalize(
                # bind(tsquery_builder.query || tsquery_builder.parse(input))
                bind(tsquery_builder.parse(input))
              )
            )
          )
        end

        # @param [String] column
        #
        # @return [ast.Node]
        def to_tsvector(column)
          ast.fn.dmetaphone_to_tsvector(
            ast.fn.string_to_dmetaphone(
              column
            )
          )
        end
    end
  end
end
