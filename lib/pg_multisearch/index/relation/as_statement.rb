# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    module AsStatement
      # @return [Boolean]
      def prepared_statement?; end

      # @return [Array]
      def bind_params; end

      # @return [Object]
      def bind(*, value)
        value
      end
    end
  end
end
