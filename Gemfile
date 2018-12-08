# frozen_string_literal: true

source 'https://rubygems.org'

ruby ENV.fetch('RUBY_VERSION').sub('ruby-', '')

gemspec

gem 'oj', require: false
gem 'pg_search', require: false

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
