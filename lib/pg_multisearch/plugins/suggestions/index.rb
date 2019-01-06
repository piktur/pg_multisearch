# frozen_string_literal: true

module PgMultisearch
  module Suggestions::Index
    extend ::ActiveSupport::Autoload

    autoload :Relation, 'pg_multisearch/plugins/suggestions/index/relation'
    autoload :Scopes,   'pg_multisearch/plugins/suggestions/index/scopes'
  end
end
