# frozen_string_literal: true

source 'https://rubygems.org'

ruby ENV.fetch('RUBY_VERSION').sub('ruby-', '')

gemspec

gem 'oj', require: false
gem 'pg', platform: :ruby
gem 'pg_search', require: false

if ENV['ACTIVE_RECORD_BRANCH']
  gem 'activerecord', github: 'rails/rails', branch: ENV['ACTIVE_RECORD_BRANCH']
  gem 'arel', github: 'rails/arel' if ENV['ACTIVE_RECORD_BRANCH'] == 'master'
end

gem 'activerecord', ENV['ACTIVE_RECORD_VERSION'] if ENV['ACTIVE_RECORD_VERSION']

eval_gemfile './Gemfile.test'

group :benchmark do
  gem 'benchmark-ips'
  gem 'ruby-prof', require: false
end

group :development do
  gem 'rubocop'
  gem 'yard', require: false
end

gem 'gemika', group: [:development, :test]
