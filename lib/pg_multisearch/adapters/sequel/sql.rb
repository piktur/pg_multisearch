# frozen_string_literal: true

module PgMultisearch::Adapters::Sequel
  module SQL
    def build_quoted(str)
      str
    end

    # @param [Object]
    #
    # @raise [TypeError] if no implicit conversion of `expression` to String
    #
    # @return [Sequel::LiteralString]
    def sql(expression)
      case expression
      when ::Sequel::BasicObject, ::Sequel::SQL::VirtualRow
        expression.sql
      when ::Sequel::LiteralString
        expression
      else
        ::Sequel.lit(expression)
      end
    end
  end
end
