# frozen_string_literal: true

module PgMultisearch
  module Strategies
    extend ::ActiveSupport::Autoload

    autoload :Dmetaphone
    autoload :Normalizer
    autoload :Strategy
    autoload :Trigram
    autoload :Tsheadline
    autoload :Tsearch
    autoload :Tsquery

    # @return [Hash]
    def self.strategies
      @strategies ||= [
        Age,
        Dmetaphone,
        Tsearch,
        Trigram
      ].map { |klass| [klass.strategy_name, klass] }.to_h
    end

    # @param [Symbol] strategy
    #
    # @return [Class]
    def self.strategy(strategy)
      klass = strategies[strategy = strategy.to_sym]

      raise(::ArgumentError, "Unknown strategy: #{strategy}") unless klass

      block_given? ? yield(strategy, klass) : klass
    end

    # @return [Symbol]
    def self.default
      Tsearch.strategy_name
    end

    # @param [Symbol] strategy
    # @param [Configuration] config
    #
    # @return [Strategy]
    def self.[](strategy, config)
      strategy(strategy) do |name, klass|
        klass.new(
          config.columns,
          config.index,
          Normalizer.new(config),
          config.strategies[name]
        )
      end
    end
  end
end
