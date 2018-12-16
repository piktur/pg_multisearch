# frozen_string_literal: true

require 'rake'
require 'pg_multisearch'

Rake::Task['pg_search:multisearch:rebuild'].clear

namespace :pg_multisearch do
  desc 'Rebuild PgMultisearch document(s) for the given model'
  task :rebuild, [:model, :schema] => :environment do |_task, args|
    raise ::ArgumentError, <<-MESSAGE.strip_heredoc unless args.model
      You must pass a model as an argument.
      Example: rake pg_multisearch:rebuild[Post]
    MESSAGE

    model_name = ::ActiveSupport::Inflector.classify(args[:model])
    model      = ::Object.const_get(model_name, false)

    connection = ::PgMultisearch::Index.connection
    original_schema_search_path = connection.schema_search_path

    begin
      connection.schema_search_path = args.schema if args.schema
      ::PgMultisearch.rebuild!(model)
    ensure
      connection.schema_search_path = original_schema_search_path
    end
  end
end
