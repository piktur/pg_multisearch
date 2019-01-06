# frozen_string_literal: true

module PgMultisearch
  module Configuration
    module Strategies
      Dmetaphone = ::Struct.new(*(Tsearch.members - [:highlight])) do
        include Base
        include Tsquery

        defaults do |obj|
          obj.dictionary       = DICTIONARY_SIMPLE
          obj.only             = __meta__.projections(:dmetaphone)
          obj.tsquery_function = :to_tsquery
          obj.tsrank_function  = :ts_rank
          obj.tsvector_column  = __meta__.projections(:dmetaphone)
          obj.weights          = __meta__.weights[0]
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
      end
    end
  end
end
