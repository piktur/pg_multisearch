# frozen_string_literal: true

module PgMultisearch
  module Configuration
    module Strategies
      Trigram = ::Struct.new(
        *Configuration::COMMON_KEYS,
        :trigram_column,
        :word_similarity,
        :weights
      ) do
        include Base

        defaults do |obj|
          obj.only           = __meta__.projections(:trigram)
          obj.trigram_column = __meta__.projections(:trigram)
          obj.weights        = __meta__.weights[0]
        end

        def only=(arr)
          self[:only] = Array(arr)
        end

        def trigram_column=(arr)
          self[:trigram_column] = Array(arr)
        end

        def weights=(arr)
          self[:weights] = Array(arr) & __meta__.weights # Filter invalid weights from input
        end
      end
    end
  end
end
