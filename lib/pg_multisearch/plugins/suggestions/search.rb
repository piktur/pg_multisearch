# frozen_string_literal: true

module PgMultisearch
  module Suggestions::Search
    # @yieldparam (see Index::Scopes#suggestions)
    #
    # @return [ActiveRecord::Relation]
    def suggestions(loader: Suggestions::Index::Relation::Loader, **, &block)
      self.scope  = index.suggestions(input, options, &block)
      self.loader = loader
      self
    end
  end
end
