# frozen_string_literal: true

module PgMultisearch
  # @see https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/calculations.rb#L418
  module Index::Relation::WithCount
    COUNT                = 'count'.freeze
    COUNT_ALIAS          = ::Arel.sql('count_column'.freeze).freeze
    COUNT_SUBQUERY_ALIAS = ::Arel.sql('subquery_for_count'.freeze).freeze

    private

      # attr_accessor :count_subquery

      # @param [ActiveRecord::Relation] relation
      # @param [String] column_name
      # @param [Boolean] distinct
      def build_count_subquery(relation, column_name, distinct = false)
        aliased_column = aggregate_column(column_name == :all ? 1 : column_name).as(COUNT_ALIAS)
        relation.select_values = [aliased_column]

        ::Arel::Nodes::SelectCore.new.tap do |obj|
          obj.projections = [operation_over_aggregate_column(COUNT_ALIAS, COUNT, distinct)]
          obj.froms       = [relation.arel.as(COUNT_SUBQUERY_ALIAS)]
        end
      end
  end
end
