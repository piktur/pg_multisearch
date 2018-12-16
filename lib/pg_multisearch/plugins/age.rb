# frozen_string_literal: true

module PgMultisearch
  # Adds a date column to `pg_search_documents` and provides mechanism to rank results by age.
  module Age
    extend Plugin

    DATE_COLUMN = 'date'

    class << self
      def apply(*args)
        super do
          %w(
            features/age
            indexable
          ).each { |f| require_relative "./age/#{f}.rb" }

          configure(*args)

          ::PgMultisearch::Indexable.extend Indexable

          feature(:age, Features::Age)
        end
      end

      def configure(column: DATE_COLUMN, **)
        options[:against] = options[:against] | Array(column)
        options[:ranked_by] ||= ':age'

        (options[:using][:age] ||= {}).tap do |h|
          h[:only] = column
          h[:sort_only] = true # exclude from WHERE condition
        end
      end
    end
  end
end
