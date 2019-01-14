# frozen_string_literal: true

module PgMultisearch
  module Strategies
    class Trigram < Strategy
      GT_SIMILARITY_THRESHOLD = ast.sql('%'.freeze).freeze
      GT_WORD_SIMILARITY_THRESHOLD_RTL = ast.sql('<%'.freeze).freeze
      GT_WORD_SIMILARITY_THRESHOLD_LTR = ast.sql('%>'.freeze).freeze

      def self.strategy_name
        :trigram
      end

      # @note Uses native PostgreSQL function `quote_literal` to prevent SQL injection.
      #
      # @return [ast.Node]
      def normalized_query
        normalize(
          ast.fn.quote_literal(
            bind(ast.sql(input))
          )
        )
      end
      alias query normalized_query

      # @return [ast.Node]
      def rank(*)
        if word_similarity?
          word_similarity
        else
          similarity
        end
      end

      # @return [ast.Node]
      def constraints
        expression = if threshold
          threshold = bind(:threshold, threshold)

          if word_similarity?
            word_similarity.gteq(threshold)
          else
            similarity.gteq(threshold)
          end
        else
          ast.nodes.infix(
            word_similarity? ? GT_WORD_SIMILARITY_THRESHOLD_RTL : GT_SIMILARITY_THRESHOLD,
            document,
            query_cte_column || normalized_query
          )
        end

        ast.nodes.group(expression)
      end

      private

        # @return [ast.Node]
        def similarity
          ast.fn.similarity(
            document,
            query_cte_column || normalized_query
          )
        end

        # @return [ast.Node]
        def word_similarity
          ast.fn.word_similarity(
            document,
            query_cte_column || normalized_query
          )
        end

        # @return [ast.Node]
        # @return [ast.Node] if {#trigram_column}
        def document
          trigram_column || normalize(super)
        end

        # @note A full `Seq Scan` will be performed if trigram column(s) are concatenated,
        #   or coalesced. We utilise only the first column and DO NOT cast to text
        #
        # @return [ast.Attribute]
        def trigram_column
          return unless config[:trigram_column]

          table[Array(config[:trigram_column])[0]]
        end

        # @return [Boolean]
        def word_similarity?
          config[:word_similarity] && postgresql_version >= 90_600
        end

        # @return [Boolean]
        def threshold
          config[:threshold].presence
        end
    end
  end
end
