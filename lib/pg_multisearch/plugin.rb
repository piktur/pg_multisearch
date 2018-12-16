# frozen_string_literal: true

module PgMultisearch
  module Plugin
    # @!attribute [rw] active
    #   @return [true] if {#apply}
    attr_accessor :active
    alias active? active

    # @return [void]
    def apply(*args)
      yield if block_given?

      self.active = true
    end

    # @return [Hash]
    def options
      ::PgMultisearch.options.tap do |options|
        options[:against] ||= []
        options[:using]   ||= {}
      end
    end

    # @param [Symbol] name
    # @param [Features::Feature] klass
    #
    # @return [void]
    def feature(name, klass)
      ::PgMultisearch::Index::Builder::FEATURE_CLASSES[name] = klass
    end
  end
end
