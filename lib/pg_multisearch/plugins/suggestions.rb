# frozen_string_literal: true

module PgMultisearch
  module Suggestions
    extend Plugin

    extend ::ActiveSupport::Autoload

    autoload :Index,      'pg_multisearch/plugins/suggestions/index'
    autoload :Search,     'pg_multisearch/plugins/suggestions/search'

    class << self
      def plugin_name
        :suggestions
      end

      def apply(*)
        super do
          ::PgMultisearch::Index::Base.extend(Index::Scopes)
          ::PgMultisearch::Search.include(Search)
        end
      end
    end
  end
end
