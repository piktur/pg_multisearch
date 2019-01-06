# frozen_string_literal: true

module PgMultisearch
  module Strategies
    class Tsearch < Strategy
      MATCH  = '@@'.freeze
      CONCAT = '||'.freeze

      def self.strategy_name
        :tsearch
      end

      # @return [ast.Node]
      def tsquery
        @tsquery ||= to_tsquery(input)
      end
      alias query tsquery

      # @todo Accept weight scale
      #
      # @return [ast.Node]
      def rank(*)
        ast.fn.send(
          tsrank_function,
          nil, # weights,
          tsvector,
          query_cte_column || tsquery,
          normalization
        )
      end

      # @return [ast.Node]
      def constraints # rubocop:disable AbcSize
        ast.nodes.group(
          ast.nodes.infix(
            MATCH,
            ast.nodes.group(tsvector),
            ast.nodes.group(query_cte_column || tsquery)
          )
        )
      end

      # @return [Boolean]
      def highlight?
        config[:highlight].present?
      end

      # @return [ast.Node]
      def highlight(source_table)
        tsheadline_builder
          .tap { |builder| builder.table = source_table }
          .call(query_cte_column || tsquery)
      end

      # @return [Tsquery]
      def tsquery_builder
        @tsquery_builder ||= Tsquery.new(index, normalizer, config).tap do |builder|
          if prepared_statement?
            builder.bind_params        = bind_params
            builder.prepared_statement = prepared_statement?
          end

          builder.table = table
        end
      end

      # @return [Tsheadline]
      def tsheadline_builder
        @tsheadline_builder ||= Tsheadline.new(index, config) do |builder|
          if prepared_statement?
            builder.bind_params        = bind_params
            builder.prepared_statement = prepared_statement?
          end
        end
      end

      private

        # @param [String] input
        #
        # @return [ast.Node]
        def to_tsquery(input)
          tsquery_builder.call(input)
        end

        # @param [String] column
        #
        # @return [ast.Node]
        def to_tsvector(column)
          ast.fn.to_tsvector(dictionary, column)
        end

        # @return [String]
        def tsvector
          tsvector_column || normalize(
            columns
              .map { |column| to_tsvector(ast.fn.coalesce(column)) }
              .reduce { |left, right| ast.nodes.infix(" #{CONCAT} ", left, right) }
          )
        end

        # The `normalization` param controls several behaviors, so it is a bit mask;
        # you can specify one or more behaviors.
        #
        # * 0  (default) ignores the document length
        # * 1  divides the rank by 1 + the logarithm of the document length
        # * 2  divides the rank by the document length
        # * 4  divides the rank by the mean harmonic distance between extents (ts_rank_cd only)
        # * 8  divides the rank by the number of unique words in document
        # * 16 divides the rank by 1 + the logarithm of the number of unique words in document
        # * 32 divides the rank by itself + 1
        #
        # @see http://www.postgresql.org/docs/8.3/static/textsearch-controls.html
        #
        # @return [Integer]
        def normalization
          config[:normalization] || 32
        end

        # @return [Symbol]
        def tsrank_function
          config[:tsrank_function] || :ts_rank
        end

        # @note A full `Seq Scan` will be performed if tsvector columns are concatenated,
        #   or coalesced. We utilise only the first column and DO NOT cast to text
        #
        # @return [ast.Attribute]
        def tsvector_column
          return unless config[:tsvector_column]

          table[Array(config[:tsvector_column])[0]]
        end
    end
  end
end
