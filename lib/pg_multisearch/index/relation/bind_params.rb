# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    class BindParams
      include ::Enumerable

      # @!attribute [rw] binds
      #   @return [Hash]
      attr_accessor :binds

      # @!attribute [rw] values
      #   @return [Hash]
      attr_accessor :values

      # @!attribute [rw] offset
      #   @return [Integer]
      attr_accessor :offset

      def initialize(offset = 0)
        @binds  = {}
        @values = {}
        @offset = offset
      end

      # @return [Integer]
      def count
        offset + binds.count
      end

      # @param [Symbol] id
      # @param [Object] value
      #
      # @return [ast.Node]
      def add(id, value)
        pos = binds.fetch(id) { binds[id] = count }
        values[id] ||= value

        Adapters.ast.nodes.bind_param("$#{pos + 1}")
      end

      # @return [Boolean]
      def empty?
        binds.length.zero?
      end

      # @return [Boolean]
      def present?
        !empty?
      end

      # @param [Symbol] id
      #
      # @return [self]
      def delete(id)
        binds.delete(id)
        values.delete(id)

        self
      end

      # @param [BindParams] other
      #
      # @return [self]
      def merge(other)
        binds.update(other.binds)
        values.update(other.values)

        self
      end

      # @yieldparam [nil] void `ActiveRecord` compatibility only
      # @yieldparam [Object] value The bound parameter value
      #
      # @return [Enumerator]
      def each(&block)
        to_a.each(&block)
      end

      # @return [Array]
      def to_ary
        arr = []
        binds.each { |id, pos| arr.insert(pos, [nil, values[id]]) }
        arr
      end
      alias to_a to_ary

      # @return [BindParams]
      def initialize_copy(source)
        super(source)

        self.binds  = source.binds.dup
        self.values = source.values.dup

        self
      end
    end
  end
end
