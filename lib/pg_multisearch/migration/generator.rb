# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/base'

module PgMultisearch
  module Migration
    class Generator < ::Rails::Generators::Base
      ::Rails::Generators.hide_namespace namespace

      def self.inherited(base)
        super

        base.source_root ::File.expand_path('templates', __dir__)
      end

      def create_migration
        now = ::Time.now.utc
        filename = "#{now.strftime('%Y%m%d%H%M%S')}_#{migration_name}.rb"

        template "#{migration_name}.rb.erb", "db/migrate/#{filename}"
      end

      private

      def connection
        ::ActiveRecord::Base.connection
      end

      def postgresql_version(operator = '<', version)
        "::ActiveRecord::Base.connection.send(:postgresql_version) #{operator} #{version}"
      end

      def read_sql_file(filename = __callee__)
        dir = ::File.expand_path('../../../sql', __dir__)
        filename = ::File.join(dir, "#{filename}.sql")

        ::File.read(filename).strip
      end
    end
  end
end
