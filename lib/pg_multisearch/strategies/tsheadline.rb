# frozen_string_literal: true

module PgMultisearch
  module Strategies
    class Tsheadline < Strategy
      def self.strategy_name
        :tsheadline
      end

      # @param [Index::Base] index
      # @param [Configuration::Base, Hash] config
      #
      # @option (see HIGHLIGHT_OPTIONS)
      # @option [Array<String>] config :fields
      #   A list of JSON paths
      # @option [Proc, ast.Node] config :document (#document)
      #   A function to compile the document
      def initialize(index, config)
        @index       = index
        @config      = config[:highlight] || EMPTY_HASH
        @projections = []
      end

      # @param [ast.Node tsquery
      # @param [Proc, ast.Node] document
      #
      # @return [ast.Node]
      def call(tsquery, document = config[:document])
        case document
        when ::Proc   then ts_headline(tsquery, &document)
        when ast.Node then ts_headline(tsquery, document)
        else
          # @todo Raise if config[:fields] nil; we cannot build the document without knowing
          # which fields to use.
          ts_headline(tsquery, self.document)
        end
      end

      # @return [Array<Symbol>]
      def projections
        @projections[0] ||= :data
      end

      # @todo Rebuild the tsquery if dictionary other than that utilised by Tsearch.
      #
      # @yieldparam [self] strategy
      #   Yields self to the block so that, if necessary,
      #   additional columns may be added to {#projections}
      # @yieldparam [Adapters::AST] ast
      #   Yields {#ast} to the block
      # @yieldparam [ast.Table] table
      #   Yields {#table} to the block
      # @yieldreturn [ast.Node]
      #
      # @return [ast.Node]
      def ts_headline(tsquery, document = nil)
        document = yield(self, ast, table) if block_given?

        ast.fn.ts_headline(
          nil,
          document,
          tsquery,
          config
        )
      end

      protected

        # @return [ast.Node]
        def document
          ast.fn.jsonb_fields_to_text(
            table[index.projection(:data)],
            Array(config.fetch(:fields))
          )
        end
    end
  end
end
