# frozen_string_literal: true

module PgMultisearch
  module Adapters::Arel
    module Functions
      include SQL
      include Nodes

      TIMESTAMP = ::Arel.sql('TIMESTAMP'.freeze).freeze

      # @return [Arel::Nodes::SqlLiteral]
      def current_timestamp
        ::Arel.sql('current_timestamp'.freeze)
      end

      # @return [Arel::Nodes::NamedFunction]
      def coalesce(expression)
        fn(
          'coalesce'.freeze,
          [
            ::Arel.sql("#{expression}::text"),
            ::Arel.sql("''".freeze)
          ]
        )
      end

      # @param [String]
      #
      # @return [Arel::Nodes::NamedFunction]
      def quote_literal(expression)
        fn(
          'quote_literal'.freeze,
          [
            node(expression)
          ]
        )
      end

      # @param [Array<String, Numeric, Boolean>]
      #
      # @return [Arel::Nodes::NamedFunction]
      def row(values)
        fn(
          'row'.freeze,
          [
            group(values)
          ]
        )
      end

      # @param (see #row)
      #
      # @return [Arel::Nodes::NamedFunction]
      def row_to_json(values)
        fn(
          'row_to_json'.freeze,
          [
            row(values)
          ]
        )
      end

      def age(expression)
        fn(
          'age'.freeze,
          [
            expression # to_timestamp(expression)
          ]
        )
      end

      def now
        fn(
          'now'.freeze,
          EMPTY_ARRAY
        )
      end

      def to_timestamp(input)
        fn(
          'CAST'.freeze,
          [
            input.as(TIMESTAMP)
          ]
        )
      end

      def row_number
        fn(
          'row_number'.freeze,
          EMPTY_ARRAY
        )
      end

      def cume_dist
        fn(
          'cume_dist'.freeze,
          EMPTY_ARRAY
        )
      end

      def percent_rank
        fn(
          'percent_rank'.freeze,
          EMPTY_ARRAY
        )
      end

      # @see https://www.postgresql.org/docs/9.6/pgtrgm.html
      def similarity(left, right)
        fn(
          'similarity'.freeze,
          [
            left,
            right
          ]
        )
      end

      # @see https://www.postgresql.org/docs/9.6/pgtrgm.html
      def word_similarity(left, right)
        fn(
          'word_similarity'.freeze,
          [
            left,
            right
          ]
        )
      end

      # @param [Array<Float, Float, Float, Float>] weights
      # @param [Arel::Nodes::NamedFunction] tsvector
      # @param [Arel::Nodes::NamedFunction] tsquery
      # @param [Integer] normalization
      #
      # @return [Arel::Nodes::NamedFunction]
      def ts_rank(weights, tsvector, tsquery, normalization = 32)
        # "ARRAY[#{weights.join(',')}]::float4[]"
        fn(
          'ts_rank'.freeze,
          [
            *weights,
            group(tsvector),
            group(tsquery),
            normalization
          ]
        )
      end

      # @param (see #ts_rank)
      #
      # @return [Arel::Nodes::NamedFunction]
      def ts_rank_cd(weights, tsvector, tsquery, normalization = 32)
        # "ARRAY[#{weights.join(',')}]::float4[]"
        fn(
          'ts_rank_cd'.freeze,
          [
            *weights,
            group(tsvector),
            group(tsquery),
            normalization
          ]
        )
      end

      # @param [String] dictionary
      # @param [String] column
      #
      # @return [Arel::Nodes::NamedFunction]
      def to_tsvector(dictionary, expression)
        fn(
          'to_tsvector'.freeze,
          [
            dictionary,
            expression
          ]
        )
      end

      # @param [String]
      #
      # @return [Arel::Nodes::NamedFunction]
      def string_to_dmetaphone(str)
        fn(
          'string_to_dmetaphone'.freeze,
          [
            str
          ]
        )
      end

      # @param [String]
      #
      # @return [Arel::Nodes::NamedFunction]
      def tsquery_to_dmetaphone(str)
        fn(
          'tsquery_to_dmetaphone'.freeze,
          [
            str
          ]
        )
      end

      # @param [String] str
      # @param [String] dictionary
      #
      # @return [Arel::Nodes::NamedFunction]
      def dmetaphone_to_tsquery(str, dictionary = nil)
        fn(
          'dmetaphone_to_tsquery'.freeze,
          [
            str,
            *dictionary
          ]
        )
      end

      # @param [String] str
      # @param [String] dictionary
      #
      # @return [Arel::Nodes::NamedFunction]
      def dmetaphone_to_tsvector(str, dictionary = nil)
        fn(
          'dmetaphone_to_tsvector'.freeze,
          [
            str,
            *dictionary
          ]
        )
      end

      # @!method to_tsquery
      # @!method plainto_tsquery
      # @!method phraseto_tsquery
      # @!method websearch_to_tsquery
      # @param [String, Symbol] dictionary
      # @param [String] str
      # @return [Arel::Nodes::NamedFunction]

      def to_tsquery(dictionary, str)
        fn(
          'to_tsquery'.freeze,
          [
            build_quoted(dictionary),
            str
          ]
        )
      end

      def plainto_tsquery(dictionary, str)
        fn(
          'plainto_tsquery'.freeze,
          [
            build_quoted(dictionary),
            str
          ]
        )
      end

      def phraseto_tsquery(dictionary, str)
        fn(
          'phraseto_tsquery'.freeze,
          [
            build_quoted(dictionary),
            str
          ]
        )
      end

      def websearch_to_tsquery(dictionary, str)
        fn(
          'websearch_to_tsquery'.freeze,
          [
            build_quoted(dictionary),
            str
          ]
        )
      end

      # @param [Arel::Attributes::Attribute] source
      # @param [Array<String, Array<String>>] paths
      #
      # @return [Arel::Nodes::NamedFunction]
      def jsonb_fields_to_text(source, paths)
        fn(
          'jsonb_fields_to_text'.freeze,
          [
            source,
            paths
          ]
        )
      end

      # @param [Arel]
      #
      # @return [Arel::Nodes::NamedFunction]
      def ts_headline(dictionary, document, tsquery, options)
        fn(
          'ts_headline'.freeze,
          [
            *dictionary,
            document,
            tsquery,
            highlight_options(options)
          ]
        )
      end

      HIGHLIGHT_OPTIONS = ::PgMultisearch::Configuration::Strategies::HIGHLIGHT_OPTIONS.map do |option|
        [option, ::PgMultisearch.inflector.camelize(option).freeze]
      end.freeze
      private_constant :HIGHLIGHT_OPTIONS

      # @see https://www.postgresql.org/docs/9.5/textsearch-controls.html
      #   12.3.4. Highlighting Results
      #
      # @return [String]
      def highlight_options(options)
        return unless options.is_a?(::Hash)

        build_quoted(
          HIGHLIGHT_OPTIONS
            .reduce([]) { |arr, (k1, k2)| options[k1] ? arr << "#{k2}=#{options[k1]}" : arr }
            .tap { |arr| return if arr.empty? } # rubocop:disable NonLocalExitFromIterator
            .join(', '.freeze)
        )
      end
    end
  end
end
