# frozen_string_literal: true

module PgMultisearch
  class Type < ::Object
    # @!attribute [r] klass
    #   @return [ActiveRecord::Base]
    attr_reader :klass

    # @!attribute [r] index
    #   @return [Integer]
    attr_reader :index

    def initialize(klass, index)
      @klass = klass
      @index = index
    end

    # @return [String]
    def human(count: 2)
      klass.model_name.human(count: count)
    end

    # @return [String]
    def to_s
      klass.name
    end
    alias to_str to_s

    alias to_i index

    def inspect
      "#<Type[#{self}] index=#{to_i}>"
    end

    def pretty_print(pp)
      pp.text inspect
    end
  end
  private_constant :Type
end
