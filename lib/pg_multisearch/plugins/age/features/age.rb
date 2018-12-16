# frozen_string_literal: true

module PgMultisearch
  module Features
    class Age < Feature
      TIMESTAMP = ::Arel.sql('TIMESTAMP').freeze
      ALIAS = 'age_rank'

      # @return [Arel::Nodes::Node]
      def rank
        ::Arel::Nodes::Grouping.new(expression)
      end

      # @return [void]
      def conditions; end

      private

        def expression
          window = ::Arel::Nodes::Window.new.order(desc(age))

          cume_dist.over(window)
        end

        def column
          table[columns.first.name]
        end

        def age
          fn('age', [to_timestamp(column)])
        end

        def cume_dist
          fn('cume_dist', EMPTY_ARRAY)
        end

        def percent_rank
          fn('percent_rank', EMPTY_ARRAY)
        end

        def to_timestamp(input)
          fn('CAST', [input.as(TIMESTAMP)])
        end
    end
  end
end
