# frozen_string_literal: true

require 'pg_search'
require 'oj'

Oj.default_options = {
  mode: :rails,
  use_as_json: true
}

# PgMultisearch extends [pg_search](https://github.com/Casecommons/pg_search) providing better
# support for multi table search index.
module PgMultisearch
  extend ::ActiveSupport::Autoload

  autoload :Arel
  autoload :Configuration
  autoload :Compatibility
  autoload :Document
  autoload :Features
  autoload :Index
  autoload :Multisearchable
  autoload :Preloader
  autoload :Railtie
  autoload :Relation
  autoload :Search
  autoload :Type
  autoload :Types

  mattr_accessor :options
  self.options = {}
end

require_relative './constants.rb'
