# frozen_string_literal: true

module PgMultisearch
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'pg_multisearch/tasks.rb'
    end

    generators do
      require 'pg_multisearch/generators'
    end

    config.to_prepare do
      ::PgMultisearch.unaccent_function ||= 'unaccent'.freeze

      # [Index::Base, *Index::Base.descendants].each do |klass|
      #   klass.instance_variable_remove(:@config)
      # end

      # ::PgMultisearch.remove_instance_variable(:@config)

      # initializer = ::Rails.root.join('config/initializers', 'pg_multisearch.rb')
      # load(initializer) if ::File.exist?(initializer)
    end
  end
end
