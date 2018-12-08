# frozen_string_literal: true

require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'

require_relative './support/application.rb'

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'

require 'database_cleaner'
require 'gemika'

begin
  ActiveRecord::Migration.check_pending!
rescue ActiveRecord::PendingMigrationError => err
  puts err.message.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_path = "#{__dir__}/fixtures"

  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.around do |example|
    DatabaseCleaner.cleaning { example.run }
  end

  config.after(:suite) do
    DatabaseCleaner.clean!
  end

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
end

require_relative './support/with_model.rb'
require_relative './support/database.rb'
