# frozen_string_literal: true

module PgMultisearch::Adapters
  class AST
    # @!attribute [r] fn
    # @!attribute [r] math
    # @!attribute [r] nodes
    # @return [Object]
    attr_accessor :fn, :math, :nodes

    # @param [Module] adapter
    def initialize(adapter)
      extend(adapter.const_get(:SQL, false))

      @nodes = build(adapter, :Nodes).freeze
      @fn    = build(adapter, :Functions).freeze
      @math  = build(adapter, :Math).freeze

      freeze
    end

    private

      def build(adapter, const)
        ::Object.new.extend(adapter.const_get(const, false))
      end
  end
end
