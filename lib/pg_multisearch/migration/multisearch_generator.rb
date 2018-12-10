# frozen_string_literal: true

require 'pg_multisearch/migration/generator'

# * Backport PostrgreSQL v11 `jsonb_to_tsvector('simple', '{}'::jsonb, '["all"]'::jsonb)`
#   Concatenate all JSON values or those matching given JSON type(s).
module PgMultisearch::Migration
  class MultisearchGenerator < Generator
    def migration_name
      'create_pg_multisearch_documents'
    end

    private

      %i(
        alter_table_pg_search_documents_searchable_type
        create_function_jsonb_to_tsvector
        create_function_pg_search_document
        create_function_pg_search_words
        create_index_pg_search_documents_header
        create_index_pg_search_suggestions
        create_trigger_pg_search_tsvectorupdate
        create_type_searchable
        drop_function_jsonb_to_tsvector
        drop_function_pg_search_document
        drop_function_pg_search_words
        drop_trigger_pg_search_tsvectorupdate
        drop_type_searchable
      ).each { |aliaz| alias_method aliaz, :read_sql_file }

      def create_type_searchable
        format(read_sql_file(__method__), ruby: enum)
      end

      def enum
        ::Search.types.map { |t| connection.quote(t.to_s) }.join(',')
      end

      def load_migration(name)
        migration = ::Dir["db/migrate/*_#{name}.rb"][0]

        load(migration) if migration
      end
  end
end
