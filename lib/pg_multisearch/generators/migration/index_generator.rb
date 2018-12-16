# frozen_string_literal: true

# * Cache tsvector
# * Backport PostrgreSQL v11 `jsonb_to_tsvector('simple', '{}'::jsonb, '["all"]'::jsonb)`
#   Concatenate all JSON values or those matching given JSON type(s).
# * Store 'A' weighted lexemes within `header` column, uses 'simple' configuration to generate
#   a tsvector from the original (unstemmed) content.
#
# @see https://www.postgresql.org/docs/current/pgtrgm.html F.31.5. Text Search Integration
# @see https://www.postgresql.org/docs/9.5/textsearch-indexes.html
module PgMultisearch::Generators
  class Migration::IndexGenerator < Migration
    source_root ::File.expand_path('templates', __dir__)

    class_option(
      :types,
      type:     :array,
      required: true,
      aliases:  '-t',
      banner:   '[ARRAY[STRING,]]',
      desc:     'A list of searchable Model(s)'
    )

    def migration_name
      'create_pg_multisearch_index'
    end

    private

      %i(
        alter_table_pg_search_documents_searchable_type
        create_function_dmetaphone_to_tsquery
        create_function_dmetaphone_to_tsvector
        create_function_jsonb_to_tsvector
        create_function_pg_search_document_content
        create_function_pg_search_document_dmetaphone
        create_function_pg_search_document_header
        create_function_pg_search_words
        create_function_string_to_dmetaphone
        create_function_tsvector_to_array
        create_index_pg_search_documents_header
        create_index_pg_search_suggestions
        create_type_searchable
        drop_function_dmetaphone_to_tsquery
        drop_function_dmetaphone_to_tsvector
        drop_function_jsonb_to_tsvector
        drop_function_pg_search_document_content
        drop_function_pg_search_document_dmetaphone
        drop_function_pg_search_document_header
        drop_function_pg_search_words
        drop_function_string_to_dmetaphone
        drop_function_tsvector_to_array
        drop_type_searchable
      ).each { |aliaz| alias_method aliaz, :read_sql_file }

      def create_type_searchable
        format(read_sql_file(__method__), ruby: enum)
      end

      def enum
        options[:types].map { |t| connection.quote(inflector.camelize(t)) }.join(', ')
      end
  end
end
