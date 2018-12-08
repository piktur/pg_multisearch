# frozen_string_literal: true

require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'

require_relative './support/application.rb'

require 'database_cleaner'
require 'gemika'

RSpec.configure do |config|
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
end

# require_relative './support/with_model.rb'
require_relative './support/database.rb'
require_relative './support/generator.rb'
