# frozen_string_literal: true

module PgMultisearch
  class Relation::Builder < ::PgSearch::ScopeOptions
    FEATURE_CLASSES[:age]     = Features::Age
    FEATURE_CLASSES[:tsearch] = Features::TSearch

    def apply(scope)
      scope = include_table_aliasing_for_rank(scope)
      rank_table_alias = scope.pg_search_rank_table_alias(:include_counter)

      scope
        .joins(rank_join(rank_table_alias))
        .extend(DisableEagerLoading)
        .extend(WithPgSearchRank)
        .extend(Count[self])
    end

    module Count
      def self.[](builder)
        Module.new do
          define_method(:count) do
            unscoped
              .select('COUNT(*)')
              .joins(builder.subquery_join)
              .where(builder.conditions)
          end
        end
      end
    end

    def subquery_join
      @subquery_join ||= super
    end

    def conditions
      @conditions ||= super
    end

    def order_within_rank
      config.order_within_rank
    end
  end
end
