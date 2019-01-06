# frozen_string_literal: true

# rubocop:disable MethodName

module PgMultisearch::Adapters::Arel
  module Nodes
    include SQL
    include Math

    def TableAlias
      ::Arel::Nodes::TableAlias
    end

    def As
      ::Arel::Nodes::As
    end

    # def NamedFunction
    #   ::Arel::Nodes::NamedFunction
    # end

    # def InfixOperation
    #   ::Arel::Nodes::InfixOperation
    # end

    # def Grouping
    #   ::Arel::Nodes::Grouping
    # end

    # def Equality
    #   ::Arel::Nodes::Equality
    # end

    # def NotIn
    #   ::Arel::Nodes::NotIn
    # end

    # def In
    #   ::Arel::Nodes::In
    # end

    # @return [Boolean]
    def node?(expression)
      ::Arel.arel_node?(expression)
    end

    # @param [Arel::Nodes::Node, String]
    #
    # @raise [TypeError] if no implicit conversion of `expression` to String
    #
    # @return [Arel::Nodes::Node]
    def node(expression)
      return expression if node?(expression)

      ::Arel.sql(expression)
    end

    # @return [Arel::Nodes::SelectCore]
    def select
      ::Arel::Nodes::SelectCore.new
    end

    # @return [Arel::Nodes::InnerJoin]
    def inner_join(target, constraint)
      ::Arel::Nodes::InnerJoin.new(target, constraint)
    end

    # @return [Arel::Nodes::NamedFunction]
    def fn(name, args = EMPTY_ARRAY)
      ::Arel::Nodes::NamedFunction.new(name.to_s, args)
    end

    def bind_param(value)
      ::Arel::Nodes::BindParam.new(value)
    end

    # @return [Arel::Nodes::Grouping]
    def group(expression)
      ::Arel::Nodes::Grouping.new(expression)
    end

    # @return [Arel::Nodes::As]
    def as(expression, aliaz)
      ::Arel::Nodes::As.new(expression, node(aliaz))
    end

    # @return [Arel::Nodes::TableAlias]
    def table_alias(left, right)
      ::Arel::Nodes::TableAlias.new(left, right)
    end

    # @return [Arel::Nodes::UnqualifiedColumn]
    def unqualified_column(expression)
      ::Arel::Nodes::UnqualifiedColumn.new(expression)
    end

    # @return [Arel::Nodes::InfixOperation]
    def infix(operator, left, right)
      ::Arel::Nodes::InfixOperation.new(operator, left, right)
    end

    # @return [Arel::Nodes::On]
    def on(expression)
      ::Arel::Nodes::On.new(expression)
    end

    # @return [Arel::Nodes::In]
    def in(left, right)
      ::Arel::Nodes::In.new(left, right)
    end

    # @return [Arel::Nodes::NotIn]
    def not_in(left, right)
      ::Arel::Nodes::NotIn.new(left, right)
    end

    # @return [Arel::Nodes::Descending]
    def desc(expression)
      ::Arel::Nodes::Descending.new(expression)
    end

    # @return [Arel::Nodes::Ascending]
    def asc(expression)
      ::Arel::Nodes::Ascending.new(expression)
    end

    if ::ActiveRecord::VERSION::MAJOR >= 5
      def window
        ::Arel::Nodes::Window.new
      end

      def lateral(expression)
        ::Arel::Nodes::Lateral.new(expression)
      end

      def case(conditions, expression = nil, default = nil)
        node = ::Arel::Nodes::Case.new(expression, default)

        conditions
          .reduce(node) { |node, (clause, on)| node.when(clause).then(on) } # rubocop:disable ShadowingOuterLocalVariable
          .else(default)

        yield(node) if block_given?

        node
      end
    else
      def window
        ::PgMultisearch::Adapters::Arel::Nodes::Window.new
      end

      def lateral(expression)
        node = [
          'LATERAL'.freeze,
          sql(expression)
        ]

        ::Arel.sql(node.join(' '.freeze))
      end

      def case(conditions, expression = nil, default = nil)
        node = ['CASE'.freeze]
        node << sql(expression) if expression
        node.push(
          conditions.map { |(left, right)| "WHEN #{sql(left)} THEN #{sql(right)}" },
          "ELSE #{sql(default)}",
          'END'.freeze
        )

        ::Arel.sql(node.join(' '.freeze))
      end
    end
  end
end
