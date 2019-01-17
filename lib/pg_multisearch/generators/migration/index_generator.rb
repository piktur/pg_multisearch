# frozen_string_literal: true

module PgMultisearch
  module Generators
    # * Cache tsvector
    # * Backport PostrgreSQL v11 `jsonb_to_tsvector('simple', '{}'::jsonb, '["all"]'::jsonb)`
    #   Concatenate all JSON values or those matching given JSON type(s).
    # * Store 'A' weighted lexemes within `trigram` column, uses 'simple' configuration to generate
    #   a tsvector from the original (unstemmed) content.
    #
    # @see https://www.postgresql.org/docs/current/pgtrgm.html F.31.5. Text Search Integration
    # @see https://www.postgresql.org/docs/9.5/textsearch-indexes.html
    class Migration::IndexGenerator < Migration
      hide!

      source_root ::File.expand_path('templates', __dir__)

      class_option(
        :types,
        type:     :array,
        required: true,
        aliases:  '-t',
        banner:   '[ARRAY[STRING,]]',
        desc:     'A list of indexable Model(s)'
      )

      class_option(
        :table_name,
        type:     :string,
        default:  ::PgMultisearch::Index::Base.meta.table_name,
        banner:   '[STRING]'
      )

      private

        def migration_name
          'create_pg_multisearch_index'
        end

        %i(
          create_index_pg_multisearch_trigram
          drop_function_dmetaphone_to_tsquery
          drop_function_dmetaphone_to_tsvector
          drop_function_jsonb_fields_to_text
          drop_function_jsonb_to_tsvector
          drop_function_pg_multisearch_content
          drop_function_pg_multisearch_dmetaphone
          drop_function_pg_multisearch_trigram
          drop_function_pg_multisearch_words
          drop_function_string_to_dmetaphone
          drop_function_tsquery_to_dmetaphone
          drop_function_tsvector_to_array
        ).each { |aliaz| alias_method aliaz, :read_sql_file }

        def create_function
          read_sql_file(__callee__, parallel: supports_parallel? ? ' PARALLEL SAFE' : EMPTY_STRING)
        end

        %i(
          create_function_dmetaphone_to_tsquery
          create_function_dmetaphone_to_tsvector
          create_function_jsonb_fields_to_text
          create_function_jsonb_to_tsvector
          create_function_pg_multisearch_content
          create_function_pg_multisearch_dmetaphone
          create_function_pg_multisearch_trigram
          create_function_pg_multisearch_words
          create_function_string_to_dmetaphone
          create_function_tsquery_to_dmetaphone
          create_function_tsvector_to_array
        ).each { |aliaz| alias_method aliaz, :create_function }

        def alter_table_pg_multisearch_index_searchable_type
          read_sql_file(__method__, table_name: options[:table_name])
        end

        def create_index_pg_multisearch_trigram
          read_sql_file(__method__, table_name: options[:table_name])
        end

        def create_trigger_pg_multisearch_tsvectorupdate
          read_sql_file(__method__, table_name: options[:table_name])
        end

        def drop_trigger_pg_multisearch_tsvectorupdate
          read_sql_file(__method__, table_name: options[:table_name])
        end

        def drop_type_searchable
          read_sql_file(__method__, ruby: 'searchable')
        end

        def create_type_searchable
          read_sql_file(__method__, ruby: enum)
        end

        def enum
          options[:types].map { |t| connection.quote(inflector.camelize(t)) }.join(', ')
        end

        def supports_parallel?
          postgresql_version > 90_600
        end
    end
  end
end
