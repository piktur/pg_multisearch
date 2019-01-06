# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    # @note Query fragments, {Rank::Base}, {Filter::Base} and {Filter::Query} MUST track their own
    #   bind parameters. Parameters WILL BE aggregated or, in cases where the query fragment
    #   is not applicable, ignored ie. when building the {WithCount} statement.
    module AsPreparedStatement
      # @return [Boolean]
      def prepared_statement?
        true
        # !connection.send(:without_prepared_statement?, bind_values)
        # connection.instance_variable_get(:@prepared_statements)
      end

      # @return [BindParams]
      def bind_params
        @bind_params ||= BindParams.new
      end

      # @param [Symbol] id
      # @param [Object] value
      #
      # @return [ast.Node]
      def bind(id, value)
        bind_params.add(id, value)
      end
    end
  end
end
