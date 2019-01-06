# frozen_string_literal: true

# Backport Arel features
module PgMultisearch
  module Adapters::Arel
    module Nodes
      class Window < ::Arel::Nodes::Window
        attr_accessor :partitions

        def initialize
          super
          @partitions = []
        end

        def partition(*expr)
          # FIXME: We SHOULD NOT be converting these to SqlLiteral automatically
          @partitions.concat expr.map { |x|
            String === x || Symbol === x ? ::Arel::Nodes::SqlLiteral.new(x.to_s) : x
          }
          self
        end

        def eql?(other)
          super && self.partitions == other.partitions
        end
      end
    end

    module Visitors
      module DepthFirst
        def self.included(base)
          base.send(:alias_method, :visit_PgMultisearch_Arel_Nodes_Window, :terminal)
        end
      end

      module ToSql
        def visit_PgMultisearch_Arel_Nodes_Window(o, a)
          s = [
            (
              "PARTITION BY #{o.partitions.map { |x| visit(x, a) }.join(', ')}" unless
                o.partitions.empty?
            ),
            (
              "ORDER BY #{o.orders.map { |x| visit(x, a) }.join(', ')}" unless
                o.orders.empty?
            ),
            (visit o.framing, a if o.framing)
          ].compact.join ' '
          "(#{s})"
        end
      end
    end

    module ::Arel
      const_defined?(:Node) || const_set(:Node, Nodes::Node)

      def self.arel_node?(value)
        value.is_a?(::Arel::Node) ||
          value.is_a?(::Arel::Attribute) ||
          value.is_a?(::Arel::Nodes::SqlLiteral)
      end

      Nodes::Grouping.include(::Arel::Math)
      Nodes::NamedFunction.include(::Arel::Math)

      module Visitors
        DepthFirst.include(::PgMultisearch::Adapters::Arel::Visitors::DepthFirst)
        ToSql.include(::PgMultisearch::Adapters::Arel::Visitors::ToSql)
      end
    end
  end
end
