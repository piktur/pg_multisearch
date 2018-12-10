# frozen_string_literal: true

module PgMultisearch
  module Relation
    # Materializes the relation and decorates the denormalized data for each result.
    class Results
      include ::Enumerable

      # @attribute [rw] results
      #   @return [Array<Document::Base>]
      attr_reader :results

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
        results.each(&block)
      end

      # @return [Array<Document::Base>]
      def results
        return @results if defined?(@results)

        _, *projections = relation.projections

        table = relation.arel_table

        relation.projections = [
          *projections,
          table[:data],
          table[:searchable_type]
        ]

        sql = relation.to_sql

        @results = connection
          .execute(sql)
          .map { |tuple| result(tuple) }
          .tap do |arr|
            if page
              arr.extend(CollectionProxy)
              arr.relation = relation
              arr.page     = page.to_i
              arr.limit    = limit.to_i
            end
          end
      end

      protected

        # @return [Document::Base]
        def result(tuple)
          type(tuple['searchable_type']).to_document(tuple['data'], tuple['pg_search_rank'])
        end

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
