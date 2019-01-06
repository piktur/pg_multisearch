# frozen_string_literal: true

module PgMultisearch
  module Document::Index
    extend ::ActiveSupport::Autoload

    autoload :AsDocument, 'pg_multisearch/plugins/document/index/as_document'
    autoload :Rebuilder,  'pg_multisearch/plugins/document/index/rebuilder'
    autoload :Relation,   'pg_multisearch/plugins/document/index/relation'
    autoload :Scopes,     'pg_multisearch/plugins/document/index/scopes'
  end
end
