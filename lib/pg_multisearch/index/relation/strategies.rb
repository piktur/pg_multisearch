# frozen_string_literal: true

module PgMultisearch
  module Index::Relation::Strategies
    class << self
      # @param [Array<Symbol>] strategies
      # @param (see #strategy)
      #
      # @return [Array<Strategies::Strategy>]
      def call(strategies, *args, &block)
        Array(strategies).map { |strategy| strategy(strategy, *args, &block) }
      end
      alias [] call
    end

    module_function

    # @param [Symbol] strategy
    # @param [Configuration::Base] config
    # @param [String] input
    # @param [ast.Table] table
    # @param [BindParams] bind_params
    #
    # @return [Strategies::Strategy]
    def strategy(strategy, config, input, table, bind_params = nil)
      return if strategy.nil?

      strategy = Strategies[strategy, config]

      strategy.input = input
      strategy.table = table

      if bind_params
        strategy.prepared_statement = true
        strategy.bind_params        = bind_params
      end

      yield(strategy) if block_given?

      strategy
    end
  end
end
