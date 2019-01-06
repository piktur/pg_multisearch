# frozen_string_literal: true

module PgMultisearch
  module Strategies
    class Normalizer
      include ::PgMultisearch.adapter

      # @param [Configuration::Base] config
      def initialize(config)
        @config = config
      end

      # @return [ast.Node]
      # @return [String] if `expression` is a String, the quoted expression
      def add_normalization(expression)
        return expression unless ignore_accents?

        ast.nodes.fn(
          ::PgMultisearch.unaccent_function,
          [
            ast.nodes.node?(expression) ? expression : ast.build_quoted(expression)
          ]
        )
      end

      private

        attr_reader :config

        def ignore_accents?
          config.ignoring.include?(:accents)
        end
    end
  end
end
