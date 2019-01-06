# frozen_string_literal: true

module PgMultisearch
  # @return [Array]
  EMPTY_ARRAY = [].freeze

  # @return [String]
  EMPTY_STRING = ''.freeze

  # @return [Hash]
  EMPTY_HASH = {}.freeze

  # @return [Set]
  EMPTY_SET = ::Set[].freeze

  # @return [Proc]
  NOOP = ->(*) {}.freeze

  # @return [Object]
  Undefined = ::Object.new.tap do |obj|
    def obj.to_s
      'Undefined'
    end

    def obj.inspect
      'Undefined'
    end

    def obj.duplicable?
      false
    end

    # def obj.present?
    #   false
    # end

    # def obj.presence
    #   nil
    # end

    # def obj.blank?
    #   true
    # end

    # def obj.nil?
    #   false
    # end

    # Pick a value, if the first argument is not Undefined, return it back,
    # otherwise return the second arg or yield the block.
    #
    # @example
    #  def method(val = Undefined)
    #    1 + Undefined.default(val, 2)
    #  end
    #
    def obj.default(x, y = self) # rubocop:disable UncommunicativeMethodParamName
      if x.equal?(self)
        if y.equal?(self)
          yield
        else
          y
        end
      else
        x
      end
    end
  end.freeze
end
