# frozen_string_literal: true

require_relative '../migration/migration_generator.rb'

module PgMultisearch::Document::Generators
  class InstallGenerator < ::Rails::Generators::Base
    include ::PgMultisearch::Generators::Install

    hide!

    source_root ::File.expand_path('templates', __dir__)

    def create_migration
      invoke(MigrationGenerator, args, options)
    end

    def add_plugin_to_initializer
      super(:document)
    end
  end
end
