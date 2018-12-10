# frozen_string_literal: true

# @!attribute [r] klass
#   @return [ActiveRecord::Base]
# @!attribute [r] index
#   @return [Integer]
module PgMultisearch
  Type = Struct.new(:klass, :index) do
    # @return [String]
    def human(count: 2)
      klass.model_name.human(count: count)
    end

    # @return [String]
    def to_s
      klass.to_s
    end

    alias_method :to_i, :index

    def inspect
      "#<Type[#{self}] index=#{to_i}>"
    end

    def pretty_print(pp)
      pp.text inspect
    end
  end
  private_constant :Type
end
