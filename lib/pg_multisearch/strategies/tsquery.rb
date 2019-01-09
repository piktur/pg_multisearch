# frozen_string_literal: true

module PgMultisearch
  module Strategies
    class Tsquery < Strategy
      ILLEGAL_TSQUERY_CHARS = "'\?\\:‘’".freeze # /['?\\:]/.freeze
      WORD_REGEX  = /(?:\s){0,}([\&\|])(?:\s){0,}|(\s)+/.freeze
      COLON       = ':'.freeze
      CONCAT      = '||'.freeze
      LEXEME_AND  = '&'.freeze
      LEXEME_OR   = '|'.freeze
      LEXEME_NOT  = '!'.freeze
      PREFIX      = '*'.freeze
      TSQUERY_AND = '&&'.freeze
      TSQUERY_OR  = '||'.freeze
      LPAREN      = '('.freeze
      RPAREN      = ')'.freeze

      # @!attribute [rw] query
      #   @return [String]
      #   @return [ast.BindParam] if {#prepared_statement?} the substition
      attr_reader :query

      def self.strategy_name
        :tsquery
      end

      # @param [Index::Base] index
      # @param [Normalizer] normalizer
      # @param [Configuration::Base] config
      def initialize(index, normalizer, config)
        @index      = index
        @normalizer = normalizer
        @config     = config
      end

      # @return [String]
      def call(input)
        self.input = input
        self.query = input

        ast.fn.send(
          tsquery_function,
          dictionary,
          normalize(query)
        )
      end

      # @param [String] input
      def query=(input)
        @query = bind(parse(input))
      end

      # Splits `input` on {WORD_REGEX} and wraps each {#word} according to tsquery rules.
      #
      # Querytext must consist of single tokens separated by the Boolean operators `&` (AND),
      # `|` (OR) and `!` (NOT)
      #
      # @see https://www.postgresql.org/docs/9.0/textsearch-controls.html 12.3.2. Parsing Queries
      #
      # @param [String] input
      #
      # @return [String]
      def parse(input)
        return ast.build_quoted(EMPTY_STRING) if input.blank?

        input = sanitize(input)
        input = if tsquery_function == :to_tsquery
          (words = input.split(WORD_REGEX)).length == 1 ? word(words) : words(words)
        end

        ast.build_quoted(input)
      end

      protected

        # @params [Array<String>] input
        #
        # @return [String]
        def words(words)
          words.reduce([]) do |a, e|
            a << case e
            when LEXEME_OR, LEXEME_AND then e        # honour the given operator
            when SPACE                 then operator # or apply configured operator
            else word(e)
            end
          end.join(SPACE)
        end

        # @param [String] word A word within {#input}
        #
        # @return [String]
        #   If {#prefix?} or {#weighted?}, appends {COLON} to the `word`
        #   If {#prefix?}, appends {PREFIX} to the `word`
        #   If {#negated?}, preserves leading {LEXEME_NOT} otherwise removes all occurrences
        #   If {#weighted?}, appends {#weights} to the `word`
        def word(word)
          lparen, unbound, rparen = grouped(word)
          word = [*lparen, negated(unbound)]
          word.push(COLON) if prefix? || weighted?
          word.push(PREFIX) if prefix?
          word.push(weights.join) if weighted?
          word.push(rparen) if rparen

          word.join
        end

        # Warming up --------------------------------------
        #         String#slice    88.909k i/100ms
        #            String#=~    66.260k i/100ms
        # Calculating -------------------------------------
        #         String#slice      1.098M (+/- 3.5%) i/s -      5.512M in   5.025535s
        #            String#=~    778.867k (+/- 2.5%) i/s -      3.909M in   5.022305s
        #
        # Comparison:
        #         String#slice:  1098158.1 i/s
        #            String#=~:   778867.5 i/s - 1.41x  slower
        #
        # require 'benchmark/ips'
        # Benchmark.ips do |x|
        #   a = "query".freeze
        #   b = "(query)".freeze
        #   regex = /([(])?([^).]*)([)])?/.freeze
        #   lparen = '('.freeze
        #   rparen = ')'.freeze
        #
        #   slice = ->(str) {
        #     l = str[0]
        #     r = str[-1]
        #     w = str[1..-2]
        #     l == lparen || r == rparen ? [l, w, r] : [nil, str]
        #   }
        #
        #   slice2 = ->(str) {
        #     l = str.index(lparen)
        #     r = str.rindex(rparen)
        #
        #     if l && r
        #       [lparen, str[1, r - 1], rparen]
        #     elsif l
        #       [lparen, str[1, str.length - 1]]
        #     elsif r
        #       [nil, str[0, r], rparen]
        #     else
        #       [nil, str]
        #     end
        #   }
        #   match = ->(str, regex) { (s =~ regex) && [$1, $2, $3] }
        #
        #   x.report('String#slice') { slice[a]; slice[b] }
        #   x.report('String#slice 2') { slice2[a]; slice2[b] }
        #   x.report('String#=~') { match[a, regex]; match[b, regex] }
        #   x.compare!
        # end
        #
        # @todo Handle inner parentheses ie. (chao(s)
        #
        # @param [String] word
        #
        # @return [Array]
        def grouped(word)
          l = word.index(LPAREN)
          r = word.rindex(RPAREN)

          if l && r then [LPAREN, word[1, r - 1], RPAREN]
          elsif l   then [LPAREN, word[1, word.length - 1]]
          elsif r   then [nil, word[0, r], RPAREN]
          else [nil, word]
          end
        end

        # @param [String] word
        #
        # @return [String]
        #   If {#negated?}, preserves leading {LEXEME_NOT} otherwise removes all occurrences
        def negated(word)
          return word unless word.include?(LEXEME_NOT)

          if negated? && (char = word[0]) == LEXEME_NOT
            char << remove(word, LEXEME_NOT)
          else
            remove(word, LEXEME_NOT)
          end
        end

        # @return [String]
        def sanitize(word)
          remove(word, ILLEGAL_TSQUERY_CHARS)
        end

        # Warming up --------------------------------------
        #                regex    25.437k i/100ms
        #                   tr   119.139k i/100ms
        # Calculating -------------------------------------
        #                regex    267.261k (+/- 12.2%) i/s -      1.323M in   5.054374s
        #                   tr      1.566M (+/- 11.2%) i/s -      7.744M in   5.010293s
        #
        # Comparison:
        #                   tr:  1565895.5 i/s
        #                regex:   267261.3 i/s - 5.86x  slower
        #
        # require 'benchmark/ips'
        # Benchmark.ips do |x |
        #   regex = /['?\\:]/.freeze
        #   char  = "'?\\:".freeze
        #   sub   = ''.freeze
        #   input = "The 'Entity' was ? until : \ :"
        #
        #   x.report('String#gsub') { input.gsub(rx, blank) }
        #   x.report('String#tr') { input.tr(char, blank) }
        #   x.compare!
        # end
        #
        # @param [String] str
        # @param [String] char
        # @param [String] sub
        def remove(str, char, sub = EMPTY_STRING)
          str.tr(char, sub)
        end

        # @return [Array<String>]
        def weights
          config[:weights] || EMPTY_ARRAY
        end

        # @return [ast.SqlLiteral]
        def operator
          any_word? ? LEXEME_OR : LEXEME_AND
        end

        # @return [Boolean]
        def any_word?
          config[:any_word].present?
        end

        # @return [Boolean]
        def negated?
          config[:negation].present?
        end

        # @return [Boolean]
        def prefix?
          config[:prefix].present?
        end

        # @return [Symbol]
        def tsquery_function
          config[:tsquery_function]
        end

        # @return [Boolean]
        def weighted?
          weights.present?
        end
    end
  end
end
