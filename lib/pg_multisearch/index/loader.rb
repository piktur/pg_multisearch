# frozen_string_literal: true

module PgMultisearch
  class Index
    # Materializes the relation and decorates the denormalized data for each result.
    class Loader
      include ::Enumerable

      # @attribute [r] relation
      #   @return [ActiveRecord::Relation]
      attr_reader :relation

      # @attribute [r] page
      #   @return [Integer]
      attr_reader :page

      # @attribute [r] limit
      #   @return [Integer]
      attr_reader :limit

      # @param [ActiveRecord::Relation] relation
      # @param [Integer] page
      # @param [Integer] limit
      def initialize(relation, page = nil, limit = nil)
        @relation = relation
        @page     = page
        @limit    = limit
      end

      # @return [Enumerator]
      def each(&block)
        to_a.each(&block)
      end

      # @return [Array]
      def collection; relation.to_a; end
      alias to_a collection

      protected

        # @return [ActiveRecord::Base]
        def type(type)
          ::Object.const_get(type, false)
        end

      private

        def connection
          relation.connection
        end
    end
  end
end
