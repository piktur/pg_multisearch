# frozen_string_literal: true

module PgMultisearch
  module Plugin
    # @!attribute [rw] active
    #   @return [true] if {#apply}
    attr_accessor :active
    alias active? active

    # @return [void]
    def apply(*)
      self.active = true

      yield if block_given?
    end

    # @return [Configuration::Options]
    def config
      ::PgMultisearch.config
    end

    # @param [Strategies::Strategy] klass
    #
    # @return [void]
    def strategy(klass)
      ::PgMultisearch::Strategies.strategies[klass.strategy_name] = klass
    end
  end
end
