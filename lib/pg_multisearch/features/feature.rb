# frozen_string_literal: true

require 'pg_search/features/feature'

module PgMultisearch
  module Features
    class Feature < ::PgSearch::Features::Feature
      include ::PgMultisearch::Arel
      include ::PgMultisearch::Compatibility

      # @return [Integer]
      def postgresql_version
        connection.send(:postgresql_version)
      end

      def dictionary
        build_quoted(options[:dictionary] || :simple)
      end

      # @return [ActiveRecord::ConnectionAdapters::PostgreSQLAdapter]
      def connection
        model.connection
      end

      # @return [String]
      def quoted_table_name
        model.quoted_table_name
      end

      # @return [Arel::Table]
      def table
        model.arel_table
      end
    end
  end
end
