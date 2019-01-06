# frozen_string_literal: true

module PgMultisearch
  Strategies.autoload :Age, 'pg_multisearch/plugins/age/strategies/age'
  Configuration::Strategies.autoload :Age, 'pg_multisearch/plugins/age/configuration/strategies/age'

  # Adds a date column to `pg_multisearch_index` and provides mechanism to rank results by age.
  module Age
    extend ::ActiveSupport::Autoload

    autoload :Indexable, 'pg_multisearch/plugins/age/indexable'

    extend Plugin

    class << self
      def plugin_name
        :age
      end

      def apply(*args, column: 'date')
        super do
          ::PgMultisearch::Index::Base.projections.tap { |h| h[:age] = h[:date] = column }

          strategy(Strategies::Age)

          ::PgMultisearch::Indexable.extend(Indexable)
        end
      end
    end
  end
end
