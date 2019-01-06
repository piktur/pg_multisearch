# frozen_string_literal: true

module PgMultisearch
  module Suggestions::Index::Relation
    extend ::ActiveSupport::Autoload

    autoload :Builder, 'pg_multisearch/plugins/suggestions/index/relation/builder'
    autoload :Loader,  'pg_multisearch/plugins/suggestions/index/relation/loader'
  end
end
