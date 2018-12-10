# frozen_string_literal: true

module PgMultisearch
  # An ordered set indexing searchable types
  class Types < ::Object
    include ::Enumerable

    # @!attribute [r] types
    #   @return [Array<Type>]
    attr_reader :types

    # @param [Array<ActiveRecord::Base>] args A list of searchable models
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
      case input
      when ::Integer then types[input]
      when ::String then find { |t| t.to_s == input }
      when ::ActiveRecord::Base then find { |t| t.klass == input }
      else raise ::IndexError.new("#{inspect} does not include `#{input}`")
      end
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

require_relative './type.rb'
