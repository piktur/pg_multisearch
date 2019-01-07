# frozen_string_literal: true

module PgMultisearch
  # An ordered set indexing searchable types
  class Types < ::Object
    class InvalidTypeError < ::StandardError
      def initialize(types, type)
        @types = types
        @type  = type
      end

      def message
        "#{@types.inspect} does not include `#{@type}`"
      end
    end

    include ::Enumerable

    # @!attribute [r] types
    #   @return [Array<Type>]
    attr_reader :types

    # @param [Array<ActiveRecord::Base>] args A list of indexable models
    def initialize(*args)
      @types = args
        .map
        .with_index { |klass, i| Type.new(klass, i).freeze }
        .freeze
    end

    # @yieldparam [Type] type
    #
    # @return [Enumerator]
    def each(&block)
      types.each(&block)
    end

    # @param [Integer, String, ActiveRecord::Base] input
    #
    # @raise [IndexError] if input does not correspond to a {#types} member
    #
    # @return [Type]
    def [](input)
      type = case input
      when ::Integer  then types[input]
      when /^[\d]+$/  then types[input.to_i]
      when ::String   then find { |t| t.to_s == input }
      when Indexable  then find { |t| t.klass == input }
      else raise InvalidTypeError.new(self, input)
      end

      type || raise(InvalidTypeError.new(self, input))
    end

    def eql?(other)
      hash == Array(other).map(&:to_s).hash
    end
    alias == eql?

    # @return [Hash{Integer => Class}]
    def to_hash
      map { |t| [t.index, t.klass] }.to_h
    end
    alias to_h to_hash

    alias to_a types

    # @return [Integer]
    def hash
      @hash ||= types.map(&:to_s).hash
    end

    def inspect
      "#<Types[#{types.map(&:to_s).join(',')}]>"
    end
  end
  private_constant :Types
end
