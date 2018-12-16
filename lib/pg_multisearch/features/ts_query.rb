# frozen_string_literal: true

module PgMultisearch
  module Features
    class TsQuery < Feature
      UNSUPPORTED_MSG = <<-MESSAGE.strip
        Sorry, {:using => {:tsearch => {:prefix => true}}} only works in PostgreSQL 8.4 and above.
      MESSAGE

      DISALLOWED_TSQUERY_CHARACTERS = /['?\\:]/
      NEGATE      = '!'
      PREFIX      = ':*'
      LEXEME_OR   = '|'
      LEXEME_AND  = '&'
      TSQUERY_OR  = '||'
      TSQUERY_AND = '&&'

      def initialize(model, normalizer, options)
        @model = model
        @normalizer = normalizer
        @options = options
      end

      # @return [String]
      def call(input)
        return connection.quote(EMPTY_STRING) if input.blank?

        join(input).to_sql
      end

      def check!
        raise ::PgSearch::NotSupportedForPostgresqlVersion.new(UNSUPPORTED_MSG) if
          prefix? && postgresql_version < 80400
      end

      protected

        # * Split `input` on whitespace
        # * Cast each {#term} (lexeme) to `tsquery`
        # * Join AND/OR `tsquery`(ies)
        #
        # @param [String] query
        #
        # @return [Arel::Nodes::Node]
        def join(query)
          terms = (head, *tail = query.split)
          fn = any_word? ? TSQUERY_OR : TSQUERY_AND

          tail.reduce(term(head)) do |tsquery, term|
            ::Arel::Nodes::InfixOperation.new(fn, tsquery, term(term))
          end
        end

        # @param [String] term A term (lexeme) from the query
        #
        # @return [Arel::Nodes::Node]
        #   If {#prefix?}, appends `':*'` to the `term`.
        #   If {#negated?}, prepends `'!'` to  the `term`.
        def term(term)
          term, negated = negated(term)
          term = sanitize(term)
          term = connection.quote(term)
          term = normalize(term)
          term = ::Arel.sql(term)
          term = NEGATE + term if negated
          term = term + PREFIX if prefix?

          to_tsquery(dictionary, term)
        end

        # @return [Arel::Nodes::Node]
        def to_tsquery(dictionary, term)
          fn('to_tsquery', [dictionary, term])
        end

        # @return [Array<String, Boolean>]
        def negated(term)
          return term unless negated? && term.start_with?(NEGATE)

          term[0] = EMPTY_STRING
          [term, true]
        end

        # @todo Or use plain_to_tsquery
        #
        # @return [String]
        def sanitize(term)
          term.gsub(DISALLOWED_TSQUERY_CHARACTERS, EMPTY_STRING)
        end

        # @return [Boolean]
        def any_word?
          options[:any_word]
        end

        # @return [Boolean]
        def negated?
          options[:negated]
        end

        # @return [Boolean]
        def prefix?
          options[:prefix]
        end
    end
  end
end
