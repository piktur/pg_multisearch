# frozen_string_literal: true

module PgMultisearch
  module Document
    class Loader < Index::Loader
      # @return [Array<Document::Base>]
      def collection
        return @collection if defined?(@collection)

        @collection = connection
          .execute(relation.to_sql)
          .map { |tuple| member(tuple) }
          .tap do |arr|
            if page
              arr.extend(Index::Pagination)
              arr.relation = relation
              arr.page     = page.to_i
              arr.limit    = limit.to_i
            end
          end
      end
      alias to_a collection

      private

        # @return [Document::Base]
        def member(tuple)
          type(tuple['searchable_type']).to_document(tuple['data'], tuple['pg_search_rank'])
        end
    end
  end
end
