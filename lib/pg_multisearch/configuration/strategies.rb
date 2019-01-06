# frozen_string_literal: true

module PgMultisearch
  module Configuration
    module Strategies
      extend ::ActiveSupport::Autoload

      autoload :Age, 'pg_multisearch/plugins/age/configuration/strategies/age'
      autoload :Dmetaphone
      autoload :Options
      autoload :Trigram
      autoload :Tsearch
      autoload :Tsheadline
      autoload :Tsquery

      DICTIONARY_ENGLISH = 'english'.freeze
      DICTIONARY_SIMPLE  = 'simple'.freeze

      HIGHLIGHT_OPTIONS = %i(
        highlight_all
        start_sel
        stop_sel
        short_words
        min_words
        max_words
        max_fragments
        fragment_delimiter
      ).freeze

      def self.strategies
        ::PgMultisearch::Strategies.strategies.keys
      end
    end
  end
end
