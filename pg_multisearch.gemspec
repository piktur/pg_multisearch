# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('./lib', __dir__)

require_relative './lib/pg_multisearch/version.rb'

Gem::Specification.new do |s| # rubocop:disable BlockLength
  s.name        = 'pg_multisearch'
  s.authors     = %w(Daniel Small)
  s.email       = %w(piktur.io@gmail.com)
  s.homepage    = 'https://github.com/piktur/pg_multisearch'
  s.license     = 'MIT'
  s.version     = PgMultisearch::VERSION
  s.date        = '2018-12-08'
  s.summary     = 'pg_multisearch builds ActiveRecord named scopes that take advantage of PostgreSQL\'s full text search'
  s.description = s.summary
  Dir.chdir(__dir__) do
    s.files = Dir[
      'bin/*',
      'gemfiles/*',
      '{lib}/**/*.rb',
      'sql/*.sql',
      '.rspec',
      '.rubocop.yml',
      '.gitignore',
      'travis.yml',
      '.yardopts',
      'Gemfile',
      'Gemfile.lock',
      'LICENSE',
      'pg_multisearch.gemspec',
      'Rakefile',
      'README.markdown',
    ]
    s.test_files = Dir['spec/**/*.rb']
  end
  s.require_paths = %w(lib)
  s.bindir        = 'bin'

  s.required_ruby_version = '>= 2.2'

  s.add_dependency 'oj',                              '~> 3.7'
  s.add_dependency 'pg_search',                       '~> 1.0.0'

  s.add_development_dependency 'benchmark-ips',       '~> 2.7'
  s.add_development_dependency 'faker',               '~> 1.9'
  s.add_development_dependency 'pry',                 '~> 0.12'
  s.add_development_dependency 'pry-rescue',          '~> 1.4'
  s.add_development_dependency 'pry-stack_explorer',  '~> 0.4'
  s.add_development_dependency 'rake',                '~> 12.3'
  s.add_development_dependency 'redcarpet',           '~> 3.4'
  s.add_development_dependency 'rspec-rails',         '~> 3.8'
  s.add_development_dependency 'rubocop',             '~> 0.6'
  s.add_development_dependency 'ruby-prof',           '~> 0.17'
  s.add_development_dependency 'simplecov',           '~> 0.16'
  s.add_development_dependency 'yard',                '~> 0.9'
end
