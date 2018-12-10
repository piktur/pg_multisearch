# frozen_string_literal: true

class PgMultisearch::Index
  # @see PgSearch::ScopeOptions#subquery
  class ScopeOptions < ::PgSearch::ScopeOptions
    def apply(scope)
      scope = include_table_aliasing_for_rank(scope)
      rank_table_alias = scope.pg_search_rank_table_alias(:include_counter)

      scope
        .joins(rank_join(rank_table_alias))
        .order(
          "#{rank_table_alias}.rank DESC", # rank may be an array
          "#{scope.table_name}.searchable_type ASC",
          order_within_rank
        )
        .extend(DisableEagerLoading)
        .extend(WithPgSearchRank)
        # .instance_eval { reorder("#{table_name}.searchable_type ASC", *orders) }
        # .includes(:searchable) # preload searchable if not using denormalized documents
    end
  end
end
