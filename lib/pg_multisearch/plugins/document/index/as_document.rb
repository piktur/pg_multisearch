# frozen_string_literal: true

module PgMultisearch
  module Document::Index::AsDocument
    # @return [Document::Base]
    def to_document
      ::Object.const_get(searchable_type, false)
        .to_document(data || EMPTY_HASH, rank)
    end
  end
end
