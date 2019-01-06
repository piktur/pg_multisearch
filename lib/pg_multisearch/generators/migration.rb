# frozen_string_literal: true

module PgMultisearch::Generators
  class Migration < ::Rails::Generators::Base
    def create_migration
      filename = "#{timestamp}_#{migration_name}.rb"

      template "#{migration_name}.rb.erb", "db/migrate/#{filename}"
    end

    private

      def timestamp(adjust = false)
        time = (adjust ? 1.second.from_now : ::Time.now).utc
        str  = time.strftime('%Y%m%d%H%M%S')

        ::Dir["db/migrate/#{str}_*.rb"].present? ? timestamp(true) : str
      end

      def connection
        ::ActiveRecord::Base.connection
      end

      def postgresql_version(operator = '<', version)
        "::ActiveRecord::Base.connection.send(:postgresql_version) #{operator} #{version}"
      end

      def load_migration(name)
        migration = ::Dir["db/migrate/*_#{name}.rb"][0]

        "load '#{migration}'" if migration
      end

      def read_sql_file(filename = __callee__)
        dir = ::File.expand_path('../../../sql', __dir__)
        filename = ::File.join(dir, "#{filename}.sql")

        ::File.read(filename).strip
      end

      def inflector
        ::PgMultisearch.inflector
      end
  end
end
