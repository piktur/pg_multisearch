# frozen_string_literal: true

source 'https://rubygems.org'

ruby ENV.fetch('RUBY_VERSION').sub('ruby-', '')

gemspec

gem 'oj', require: false
gem 'pg_search', require: false

group :benchmark do
  gem 'benchmark-ips'
  gem 'ruby-prof', require: false
end

group :development do
  gem 'rubocop'
  gem 'yard', require: false
end

group :development, :test do
  gem 'faker', require: false
  gem 'gemika'
  gem 'pry'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
end

group :test do
  gem 'rspec'
  gem 'simplecov', require: false
end
