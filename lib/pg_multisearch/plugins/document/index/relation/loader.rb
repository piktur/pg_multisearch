# frozen_string_literal: true

module PgMultisearch
  class Document::Index::Relation::Loader < Index::Relation::Loader
    # @overload collection
    #   @return [Array<Document::Base>]

    # @return [Array<Document::Base>]
    def call(&block)
      @collection = super.map { |tuple| member(tuple) }

      return @collection unless page

      paginate
    end

    # @return [ActiveRecord::Result]
    def load
      return EMPTY_ARRAY if none?

      connection.select_all(arel, index, bind_params)
    end

    # @note {#size} MUST BE called before offset and limit, they are derived from the actual query.
    #
    # @return [Array<Document::Base>] A "paginateable" Array containing {#collection}.
    if defined?(::Kaminari)
      def paginate
        @collection = ::Kaminari.paginate_array(
          collection,
          total_count: size,
          limit:       limit.to_i,
          offset:      offset.to_i
        ).page(page.to_i)
      end
    elsif defined?(::WillPaginate)
      def paginate
        collection.paginate(
          total_entries: size,
          page:          page.to_i,
          per_page:      limit.to_i
        )
      end
    else
      def paginate
        collection.extend(Pagination)
        collection.count = size
        collection.page  = page.to_i
        collection.limit = limit.to_i
        collection
      end
    end

    protected

      # @return [Document::Base]
      def member(tuple)
        type(
          tuple[index.projection(:searchable_type)]
        ).to_document(
          tuple[index.projection(:data)],
          tuple[index.projection(:rank)],
          tuple[index.projection(:highlight)]
        )
      end
  end
end
