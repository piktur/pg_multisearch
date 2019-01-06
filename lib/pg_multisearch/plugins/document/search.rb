# frozen_string_literal: true

module PgMultisearch
  module Document::Search
    # @yieldparam (see Index::Scopes#suggestions)
    #
    # @return [ActiveRecord::Relation]
    def search(loader: Document::Index::Relation::Loader, **, &block)
      self.scope  = index.search(input, page: page, limit: limit, **options, &block)
      self.loader = loader
      self
    end
  end
end
