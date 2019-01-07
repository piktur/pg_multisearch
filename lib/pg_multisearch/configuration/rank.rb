# frozen_string_literal: true

module PgMultisearch
  module Configuration
    Rank = ::Struct.new(
      :primary,
      :secondary,
      :tertiary,
      :threshold,
      :polymorphic,
      :calc
    ) do
      include Base

      %w(primary secondary tertiary).each do |member|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{member}=(value)
            __meta__.strategy?(value) || invalid!('rank_by.#{member}', value)
            self[:#{member}] = value
          end
        RUBY
      end

      # @example
      #   config.calculation = :+
      #   config.calculation = :avg
      #   config.calculation = ->(*args) { args.map(n) { |n| n / (n + 1) }.sum / args.length }
      #
      # @param [Symbol, Proc] fn
      #
      # @see Index::Relation::Rank#calc
      # @see Adapters::AST#math
      def calculation=(fn)
        self[:calc] = case fn
        when ::Proc   then fn
        when ::Symbol then ast.math.fn?(fn) && ast.math.public_method(fn)
        end
      end
      alias_method :calc=, :calculation=

      # @raise [InvalidError] if strategies unknown
      #
      # @param [Hash{<Array<String,>,String>=>Symbol}] options
      def polymorphic=(options)
        options[:default] ||= Strategies.default
        self[:polymorphic] = options.each_value do |strategies|
          (invalid = Array(strategies).reject { |e| __meta__.strategy?(e) }).present? &&
            invalid!(__path__(:polymorphic), invalid)
        end
      end

      def threshold=(float)
        self[:threshold] = float.to_f
      end

      # @return [Hash]
      def options
        {
          calc:        self[:calc],
          polymorphic: self[:polymorphic],
          threshold:   self[:threshold]
        }
      end

      def finalize!
        self[:primary] = __meta__.default_strategy if
          self[:primary] == Undefined && self[:polymorphic] == Undefined

        super
      end

      def to_ary
        [primary, secondary, tertiary, options]
      end
      alias_method :to_a, :to_ary
    end
  end
end
