# frozen_string_literal: true

module PgMultisearch
  module Strategies
    class Age < Strategy
      def self.strategy_name
        :age
      end

      # @note Arel 4 does not support PARTITION BY; it places the ORDER BY clause first.
      #
      # @option [Boolean] options :polymorphic
      #   When true applies PARTITION BY searchable_type
      #
      # @see file:lib/pg_multisearch/adapters/arel/compatibility.rb
      #
      # @return [ast.Node]
      def rank(polymorphic: false, **) # rubocop:disable AbcSize
        expression = ast.nodes.window

        polymorphic && expression.partitions << table[index.projection(:searchable_type)]
        expression.order(ast.nodes.desc(ast.fn.age(column)))

        ast.fn.cume_dist.over(expression)
      end

      # @return [ast.Node] if {#constrained?}
      def constraints
        return unless constrained?

        ast.nodes.group(column.gteq(ast.nodes.group(ast.fn.now - max)))
      end
      alias conditions constraints

      private

        def column
          return @column if defined?(@column)

          columns = Array(config[:only])
          @column = table[columns.find { |c| columns.include?(c) }]
        end

        def constrained?
          config[:age].present?
        end

        def max
          ast.sql("interval #{bind(config[:age].join(' '))}")
        end
    end
  end
end
