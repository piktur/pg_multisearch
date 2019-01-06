# frozen_string_literal: true

module PgMultisearch
  module Document::Index::Relation
    extend ::ActiveSupport::Autoload

    autoload :Builder, 'pg_multisearch/plugins/document/index/relation/builder'
    autoload :Loader,  'pg_multisearch/plugins/document/index/relation/loader'
  end
end
