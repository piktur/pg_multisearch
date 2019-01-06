# frozen_string_literal: true

module PgMultisearch
  module Index::Relation::WithLimitBind
    def build_arel # rubocop:disable MethodLength
      super.tap do |arel|
        if ::ActiveRecord::VERSION::MAJOR < 5
          substitute = case limit_value
          when ::Arel::Nodes::BindParam
            limit_value
          when ::Integer
            bind!([nil, limit_value])
            ::Arel::Nodes::BindParam.new("$#{bind_values.length}")
          end

          arel.take(substitute)
        end
      end
    end
  end
end
