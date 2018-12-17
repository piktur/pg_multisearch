# frozen_string_literal: true

require 'rake'
require 'pg_multisearch'

Rake::Task['pg_search:multisearch:rebuild'].clear

namespace :pg_multisearch do
  desc 'Rebuild PgMultisearch document(s) for the given model'
  task :rebuild, [:model, :schema] => :environment do |_task, args|
    args  = args.to_hash
    model = args.fetch(:model) do
      msg = 'You have not specified a model. Do you want to reindex ALL searchable types? (y/n)'

      STDOUT.puts "\e[33m#{msg}\e[0m"
      input = STDIN.gets.chomp

      if input =~ /(?:y|yes|t|true|1)/i
        Search.types.map(&:to_s)
      else
        raise ArgumentError, <<-MESSAGE.strip_heredoc
          You must pass a model as an argument.
          Example: rake pg_multisearch:rebuild[Post]
        MESSAGE
      end
    end

    ::PgMultisearch.rebuild!(model, schema: args[:schema])
  end
end
