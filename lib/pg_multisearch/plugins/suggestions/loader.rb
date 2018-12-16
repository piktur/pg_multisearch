# frozen_string_literal: true

module PgMultisearch
  module Suggestions
    class Loader
      include ::Enumerable

      # @attribute [r] relation
      #   @return [ActiveRecord::Relation]
      attr_reader :relation

      # @param [ActiveRecord::Relation] relation
      # @param [Integer] limit
      def initialize(relation)
        @relation = relation
      end

      # @return [Enumerator]
      def each(&block)
        to_a.each(&block)
      end

      # @return [Array<Hash>]
      def collection
        return @collection if defined?(@collection)

        @collection = connection
          .execute(relation.to_sql)
          .map { |tuple| member(tuple) }
      end
      alias to_a collection

      private

        def member(tuple)
          type(tuple['searchable_type']).to_document(tuple['data'])
        end

        # @return [ActiveRecord::Base]
        def type(type)
          ::Object.const_get(type, false)
        end

        def connection
          relation.connection
        end
    end
  end
end
