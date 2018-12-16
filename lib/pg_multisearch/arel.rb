# frozen_string_literal: true

module PgMultisearch
  module Arel
    def desc(exp)
      ::Arel::Nodes::Descending.new(exp)
    end

    def fn(name, args = EMPTY_ARRAY)
      ::Arel::Nodes::NamedFunction.new(name.to_s, args)
    end

    def arel_wrap(str)
      ::Arel::Nodes::Grouping.new(::Arel.sql(str))
    end

    def as(expression, aliaz)
      ::Arel::Nodes::As.new(expression, ::Arel.sql(aliaz))
    end

    def current_timestamp
      ::Arel.sql('current_timestamp')
    end
  end
end
