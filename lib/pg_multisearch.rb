# frozen_string_literal: true

require 'active_record'
require 'active_support/concern'
require 'active_support/core_ext/string/strip'

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

  autoload :Adapters
  autoload :AsDocument, 'pg_multisearch/plugins/document/as_document'
  autoload :Configuration
  autoload :Index
  autoload :Indexable
  autoload :Railtie
  autoload :Search
  autoload :Strategies
  autoload :Type
  autoload :Types

  autoload_under 'plugins' do
    autoload :Age
    autoload :Document
    autoload :Plugin
    autoload :Suggestions
  end

  SWITCH = "#{name}.enabled".freeze
  private_constant :SWITCH

  class UnsupportedAdapterError < ::StandardError; end

  # ActiveRecord, ROM and Sequel
  UNSUPPORTED_ADAPTER_MSG = 'Unsupported Adapter; only ActiveRecord and Sequel supported'.freeze

  class UnsupportedPostgreSQLVersion < ::StandardError; end

  UNSUPPORTED_MSG = 'PostgreSQL version %s does not support `%s`.'.freeze

  # @param [Integer] version
  # @param [String] feature
  #
  # @raise [UnsupportedPostgreSQLVersion] if `feature` unsupported
  #
  # @return [void]
  def self.check!(version, feature)
    raise UnsupportedPostgreSQLVersion, format(UNSUPPORTED_MSG, version, feature) if
      postgresql_version < version
  end

  # @return [Integer]
  def self.postgresql_version
    ::ActiveRecord::Base.connection.send(:postgresql_version)
  end

  # @param [:MAJOR, :MINOR, :TINY, :PRE] segment
  #
  # @return [Integer]
  # def self.active_record_version(segment = :MAJOR)
  #   ::ActiveRecord::VERSION.const_get(segment.upcase)
  # end

  class << self
    # @!attribute [rw] unnaccent_function
    #   @return [String] The named SQL function to use
    attr_reader :unaccent_function

    def unaccent_function=(fn)
      check!(90_000, 'unaccent') if fn == 'unaccent'

      @unaccent_function = fn
    end

    # @!attribute [rw] inflector
    #   @return [Object]
    attr_writer :inflector

    # @raise [NameError] if {#inflector} undefined and the default is not loaded.
    def inflector
      @inflector ||= ::ActiveSupport::Inflector
    end

    # @return [Module]
    def adapter
      Adapters::Adapter
    end

    # @yieldparam [Configuration::Options]
    #
    # @return [Configuration::Options]
    def configure(&block)
      instance_exec(@config = Configuration::Options.new, Index::Base.meta, &block)

      Index::Base.meta.freeze

      @config.finalize!
    end

    # @return [Configuration::Options]
    def config
      @config ||= Configuration::Options.new
    end

    def disable
      ::Thread.current[SWITCH] = false
      yield
    ensure
      ::Thread.current[SWITCH] = true
    end

    def enabled?
      if ::Thread.current.key?(SWITCH)
        ::Thread.current[SWITCH]
      else
        true
      end
    end

    # @param [Array<ActiveRecord::Base>] model The {Indexable} type(s) to rebuild
    # @param [Hash] options
    #
    # @option [Boolean] options :clean (true) Delete existing documents before rebuild
    #
    # @return [void]
    def rebuild!(model = ::Search.types.map(&:to_s), schema: nil, **options) # rubocop:disable MethodLength
      connection = ::ActiveRecord::Base.connection
      original_schema_search_path = connection.schema_search_path

      Array(model).each do |model| # rubocop:disable ShadowingOuterLocalVariable
        model_name = inflector.classify(model)
        model      = ::Object.const_get(model_name, false)

        begin
          connection.schema_search_path = schema if schema
          Index::Rebuild.new(model, options)
        ensure
          connection.schema_search_path = original_schema_search_path
        end
      end

      true
    end
  end

  require_relative './pg_multisearch/plugins.rb'
  extend Plugins

  register(:age, Age)
  register(:document, Document)
  register(:suggestions, Suggestions)
end

ActiveSupport.on_load(:active_record) do
  require_relative './pg_multisearch/index.rb'
end

require_relative './pg_multisearch/railtie.rb' if defined?(::Rails)
