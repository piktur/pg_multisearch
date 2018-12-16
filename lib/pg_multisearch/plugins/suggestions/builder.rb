# frozen_string_literal: true

module PgMultisearch
  module Suggestions
    class Builder < Index::Builder
      def apply(model, preload: false, **, &block) # rubocop:disable MethodLength
        scope = include_table_aliasing_for_rank(model)
        rank_table_alias = scope.pg_search_rank_table_alias(:include_counter)

        scope = scope
          .extend(DisableEagerLoading)
          .extend(Load)
          .select(
            "#{quoted_table_name}.searchable_type",
            "#{quoted_table_name}.searchable_id"
          )
          .where(conditions)

        scope = scope.select("#{quoted_table_name}.data") if Document.active?

        scope = scope.instance_exec(scope, self, &block) if block_given?

        scope = preload(scope) if preload

        scope
      end

      module Load
        def load(*args)
          Document.active? ? Suggestions::Loader.new(self).to_a : super
        end
      end
    end
  end
end

require_relative './loader.rb'
