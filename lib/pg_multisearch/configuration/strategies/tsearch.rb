# frozen_string_literal: true

module PgMultisearch
  module Configuration
    module Strategies
      Tsearch = ::Struct.new(
        *COMMON_KEYS,
        :any_word,
        :dictionary,
        :highlight,
        :negation,
        :normalization,
        :prefix,
        :tsquery_function,
        :tsrank_function,
        :tsvector_column,
        :weights
      ) do
        include Base
        include Tsquery

        defaults do |obj|
          obj.dictionary       = DICTIONARY_ENGLISH
          obj.only             = __meta__.projections(:tsearch)
          obj.tsquery_function = :to_tsquery
          obj.tsrank_function  = :ts_rank
          obj.tsvector_column  = __meta__.projections(:tsearch)
          obj.weights          = __meta__.weights
          obj.highlight
        end

        def only=(arr)
          self[:only] = Array(arr)
        end

        def tsvector_column=(arr)
          self[:tsvector_column] = Array(arr)
        end

        def tsrank_function=(fn)
          self[:tsrank_function] = case (fn = fn.to_sym)
          when :ts_rank    then fn
          when :ts_rank_cd then fn
          else :ts_rank
          end
        end

        # @todo Accept scale factor per weight
        #
        # @param [Hash{String=>Float}, Array{String}] enum
        def weights=(enum)
          # case enum
          # when ::Hash  then enum
          # when ::Array then (Array(arr) & __meta__.weights).zip(1.0, 0.4, 0.2, 0.1).to_h
          # end

          self[:weights] = (Array(enum) & __meta__.weights).sort # Filter invalid weights from input
        end

        def highlight
          fetch_or_store(:highlight) { Tsheadline.new(__meta__: __meta__) }
            .tap { |obj| yield(obj, __meta__) if block_given? }
        end

        def to_hash
          super.tap do |h|
            h[:highlight] = self[:highlight].to_h
          end
        end
        alias_method :to_h, :to_hash
      end
    end
  end
end
