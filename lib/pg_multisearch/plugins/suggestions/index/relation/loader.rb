# frozen_string_literal: true

module PgMultisearch
  class Suggestions::Index::Relation::Loader < Index::Relation::Loader
    # @return [Array<Hash>]
    def collection
      return @collection if defined?(@collection)

      @collection = load.map { |tuple| member(tuple) }
    end
    alias to_a collection

    private

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
