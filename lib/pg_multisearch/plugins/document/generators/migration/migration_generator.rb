# frozen_string_literal: true

# * Backport PostrgreSQL v11 `jsonb_to_tsvector('simple', '{}'::jsonb, '["all"]'::jsonb)`
#   Concatenate all JSON values or those matching given JSON type(s).
#
# @see https://www.postgresql.org/docs/9.5/textsearch-indexes.html
module PgMultisearch
  module Document::Generators
    class MigrationGenerator < Generators::Migration
      hide!

      source_root ::File.expand_path('templates', __dir__)

      class_option(
        :index,
        type: :boolean,
        default: false
      )

      private

        def migration_name
          'add_data_to_pg_multisearch_index'
        end
    end
  end
end
