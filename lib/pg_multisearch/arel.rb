# frozen_string_literal: true

module PgMultisearch
  module Arel
    def desc(exp)
      ::Arel::Nodes::Descending.new(exp)
    end

    def fn(name, args = ::EMPTY_ARRAY)
      ::Arel::Nodes::NamedFunction.new(name.to_s, args)
    end

    def arel_wrap(sql_string)
      ::Arel::Nodes::Grouping.new(::Arel.sql(sql_string))
    end
  end
end
