# frozen_string_literal: true

# rubocop:disable MethodName

module PgMultisearch::Adapters::Arel
  module SQL
    def Node
      ::Arel::Nodes::Node
    end

    def Attribute
      ::Arel::Attributes::Attribute
    end

    def Table
      ::Arel::Table
    end

    def SqlLiteral
      ::Arel::Nodes::SqlLiteral
    end

    def SelectManager
      ::Arel::SelectManager
    end

    # @return [Arel::SelectManager]
    def select_manager(engine, table)
      ::Arel::SelectManager.new(engine, table)
    end

    # @return [Arel::Table]
    def table(*args)
      ::Arel::Table.new(*args)
    end

    # @return [Arel::Nodes::SqlLiteral]
    def star
      ::Arel.star
    end

    # @param [Arel::Nodes::Node, String]
    #
    # @raise [TypeError] if no implicit conversion of `expression` to String
    #
    # @return [Arel::Nodes::SqlLiteral]
    def sql(expression)
      case expression
      when ::Arel::Node, ::Arel::Attribute
        expression.to_sql
      when ::Arel::Nodes::SqlLiteral
        expression
      else
        ::Arel.sql(expression)
      end
    end

    if defined?(::Arel::Nodes::Quoted)
      def build_quoted(str)
        ::Arel::Nodes.build_quoted(str)
      end
    else
      def build_quoted(str)
        str
      end
    end
  end
end
