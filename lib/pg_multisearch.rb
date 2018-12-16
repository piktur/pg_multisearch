# frozen_string_literal: true

require 'pg_search'
require 'oj'

Oj.default_options = {
  mode: :rails,
  use_as_json: true
}

require_relative './pg_multisearch/constants.rb'

# PgMultisearch extends [pg_search](https://github.com/Casecommons/pg_search) providing better
# support for multi table search index.
module PgMultisearch
  extend ::ActiveSupport::Autoload

  autoload :Arel
  autoload :AsDocument, 'pg_multisearch/plugins/document/as_document'
  autoload :Compatibility
  autoload :Configuration
  autoload :Features
  autoload :Index
  autoload :Indexable
  autoload :Plugin
  autoload :Railtie
  autoload :Search
  autoload :Type
  autoload :Types

  autoload_under 'plugins' do
    autoload :Age
    autoload :Document
    autoload :Suggestions
  end

  mattr_accessor :options
  self.options = { against: [], using: {} }

  require_relative './pg_multisearch/plugins.rb'
  extend Plugins

  register(:age)         { Age }
  register(:document)    { Document }
  register(:suggestions) { Suggestions }

  # @param [ActiveRecord::Base] model The {Indexable} type to rebuild
  # @param [Hash] options
  #
  # @option [Boolean] options :clean (true) Delete existing documents before rebuild
  #
  # @return [void]
  def self.rebuild!(model, options = EMPTY_HASH)
    Index::Rebuild.new(model, options)

    true
  end
end

require_relative './pg_multisearch/railtie.rb'
