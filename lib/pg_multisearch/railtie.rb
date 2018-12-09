# frozen_string_literal: true

module PgMultisearch
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'pg_multisearch/tasks.rb'
    end

    generators do
      require 'pg_search/migration/multisearch_generator.rb'
      require 'pg_search/migration/suggestions_generator.rb'
    end
  end
end
