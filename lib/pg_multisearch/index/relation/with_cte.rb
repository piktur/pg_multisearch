# frozen_string_literal: true

module PgMultisearch
  # Provides ability to apply Common Table Expressions (CTE) to an `ActiveRecord::Relation`
  # @see https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/query_methods.rb
  module Index::Relation::WithCTE
    # MULTI_VALUE_METHODS << :with

    if ::ActiveRecord::VERSION::MAJOR >= 5
      def with_values
        get_value(:with)
      end

      def with_values=(value)
        set_value(:with, value)
      end
    else
      def with_values
        @values[:with] || []
      end

      def with_values=(values)
        raise ImmutableRelation if @loaded

        @values[:with] = values
      end
    end

    def with!(value)
      self.with_values += Array(value)
      self
    end

    def with(value)
      spawn.with!(value)
    end

    def build_arel
      super.tap do |arel|
        arel.with(with_values)
      end
    end
  end
end
