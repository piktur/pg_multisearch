# frozen_string_literal: true

module PgMultisearch
  module Configuration
    Filter = ::Struct.new(
      :primary,
      :secondary,
      :tertiary
    ) do
      include Base

      defaults do |obj|
        obj.primary = __meta__.default_strategy
      end

      %w(primary secondary tertiary).each do |member|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{member}=(value)
            __meta__.strategy?(value) || invalid!('filter_by.#{member}', value)
            self[:#{member}] = value
          end
        RUBY
      end

      def to_ary
        [primary, secondary, tertiary]
      end
      alias_method :to_a, :to_ary
    end
  end
end
