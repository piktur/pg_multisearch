# frozen_string_literal: true

module PgMultisearch
  module Features
    class TSearch < Feature
      MATCH = '@@'

      def self.valid_options
        super + %i(
          dictionary
          prefix
          negation
          any_word
          normalization
          tsvector_column
          highlight
        )
      end

      # @!attribute [rw] tsquery
      #   @return [Arel::Nodes::Node]
      attr_accessor :tsquery

      # @!attribute [r] ts_query_builder
      #   @return [TsQuery]
      attr_reader :ts_query_builder

      # @!attribute [r] ts_headline_builder
      #   @return [TsHeadline]
      attr_reader :ts_headline_builder

      def initialize(*args)
        super

        @ts_query_builder    ||= TsQuery.new(model, normalizer, options)
        @ts_headline_builder ||= TsHeadline.new(model, options)

        ts_query_builder.check!
        ts_headline_builder.check!

        @tsquery = ::Arel.sql(to_tsquery(query))
      end

      def conditions
        ::Arel::Nodes::Grouping.new(
          ::Arel::Nodes::InfixOperation.new(
            MATCH,
            arel_wrap(tsvector),
            arel_wrap(tsquery)
          )
        )
      end

      def rank
        arel_wrap(ts_rank(tsvector, tsquery).to_sql)
      end

      def highlight
        arel_wrap(ts_headline_builder.call(tsvector, tsquery).to_sql)
      end

      private

        def to_tsquery(input)
          @ts_query_builder.call(input)
        end

        def ts_rank(tsvector, tsquery)
          fn(
            'ts_rank',
            [
              ::Arel::Nodes::Grouping.new(tsvector),
              ::Arel::Nodes::Grouping.new(tsquery),
              normalization
            ]
          )
        end

        def to_tsvector(column)
          fn(
            'to_tsvector',
            [
              dictionary,
              ::Arel.sql(normalize(column.to_sql))
            ]
          )
        end

        # @return [String]
        def tsvector
          terms = if tsvector_column
            ::Array.wrap(tsvector_column).map do |column|
              "#{quoted_table_name}.#{connection.quote_column_name(column)}"
            end
          else
            columns_to_use.map { |column| to_tsvector(column).to_sql }
          end

          ::Arel.sql(terms.join(' || '))
        end

        # The integer option controls several behaviors, so it is a bit mask;
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
        def normalization
          options[:normalization] || 0
        end

        def tsvector_column
          options[:tsvector_column]
        end

        def columns_to_use
          return columns || EMPTY_ARRAY unless tsvector_column

          columns.select { |c| c.is_a?(::PgMultisearch::Configuration::ForeignColumn) }
        end
    end
  end
end
