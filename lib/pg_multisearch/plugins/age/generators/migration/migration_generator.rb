# frozen_string_literal: true

module PgMultisearch
  module Age::Generators
    class MigrationGenerator < Generators::Migration
      hide!

      source_root ::File.expand_path('templates', __dir__)

      class_option(
        :column,
        type: :string,
        default: 'date'
      )

      private

        def migration_name
          'add_date_to_pg_multisearch_index'
        end
    end
  end
end
