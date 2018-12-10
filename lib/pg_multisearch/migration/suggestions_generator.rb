# frozen_string_literal: true

require 'pg_multisearch/migration/generator'

# @see https://www.postgresql.org/docs/current/pgtrgm.html F.31.5. Text Search Integration
module PgMultisearch::Migration
  class SuggestionsGenerator < Generator
    def migration_name
      'create_pg_multisearch_suggestions'
    end

    private

      alias create_index_pg_search_suggestions read_sql_file

      # Build a tsvector from 'A' weighted pg_search_documents.content
      # Use 'simple' configuration to generate a tsvector from the original (unstemmed) content.
      #
      # @see file:sql/create_table_pg_search_suggestions.sql
      def create_table_pg_search_suggestions
        format(read_sql_file(__method__), ruby: tsvector_from_content)
      end

      # @see file:sql/tsvector_from_content.sql
      def tsvector_from_content
        connection.quote read_sql_file(__method__)
      end
  end
end
