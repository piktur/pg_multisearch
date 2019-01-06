# frozen_string_literal: true

module PgMultisearch
  # COMPATIBILITY: ActiveRecord < 5
  #   `ActiveRecord::Relation::QueryMethods#build_arel` casts
  #   `#offset_value` to an Integer without regard for existing bind parameter reference.
  module Index::Relation::WithOffsetBind
    def build_arel # rubocop:disable MethodLength
      super.tap do |arel|
        if ::ActiveRecord::VERSION::MAJOR < 5
          substitute = case offset_value
          when ::Arel::Nodes::BindParam
            offset_value
          when ::Integer
            bind!([nil, offset_value])
            ::Arel::Nodes::BindParam.new("$#{bind_values.length}")
          end

          arel.skip(substitute)
        end
      end
    end
  end
end
