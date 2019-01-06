# frozen_string_literal: true

module PgMultisearch
  module Configuration
    module Strategies
      Age = ::Struct.new( # rubocop:disable BlockLength
        *COMMON_KEYS,
        :age,
        :unit
      ) do
        include Base

        # @see ActiveSupport::Duration::PARTS
        YEARS   = 'years'.freeze
        MONTHS  = 'months'.freeze
        WEEKS   = 'weeks'.freeze
        DAYS    = 'days'.freeze
        HOURS   = 'hours'.freeze
        MINUTES = 'minutes'.freeze
        SECONDS = 'seconds'.freeze

        defaults do |obj|
          obj.only      = __meta__.projections(:date)
          obj.rank_only = true # ignore {Strategies::Age#constraints}
          obj.unit      = DAYS
        end

        def age
          self[:age] ? [self[:age], unit] : EMPTY_ARRAY
        end

        def age=(input)
          age, unit = case input
          when ::Array  then input
          when ::String then input.split
          else input
          end

          self[:age]  = age.to_i
          self[:unit] = unit
        end

        def only=(arr)
          self[:only] = Array(arr)
        end
      end
    end
  end
end
