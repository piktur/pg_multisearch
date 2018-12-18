# frozen_string_literal: true

module PgMultisearch
  class Index
    class Builder < ::PgSearch::ScopeOptions
      FEATURE_CLASSES[:tsearch]    = Features::TSearch
      FEATURE_CLASSES[:dmetaphone] = Features::DMetaphone

      def apply(model, preload: false, **, &block) # rubocop:disable MethodLength
        return none(model) if config.query.empty?

        scope = include_table_aliasing_for_rank(model)

        self.rank_table_alias = scope

        scope = scope
          .extend(DisableEagerLoading)
          .extend(WithPgSearchRank)
          .extend(WithPgSearchHighlight[feature_for(:tsearch)])
          .extend(Count[conditions])
          .extend(Load)
          .joins(rank_join)

        scope = scope.instance_exec(scope, self, &block) if block_given?

        scope = scope.order(order_within_rank) if order_within_rank

        scope = preload(scope) if preload

        scope
      end

      module Load
        def load(*)
          super()
        end
      end

      module Count
        def self.[](rank_constraints)
          Module.new do
            define_method(:count) do
              unscoped
                .select('COUNT(*)')
                .where(constraints.reduce(&:and))
                .where(rank_constraints)
            end
          end
        end
      end

      def conditions
        @conditions ||= super
      end

      def subquery_join
        @subquery_join ||= super
      end

      attr_reader :rank_table_alias

      def rank_table
        @rank_table ||= ::Arel::Table.new(rank_table_alias)
      end

      def rank_table_alias=(scope)
        @rank_table_alias = scope.pg_search_rank_table_alias(:include_counter)
      end

      private

        # @param [ActiveRecord::Base] model
        #
        # @return [ActiveRecord::NullRelation]
        def none(model)
          model.none.extend(Load)
        end

        def preload(scope)
          scope = scope.includes(:searchable)

          Preloader.call(scope)

          scope
        end

        def rank_join
          model.arel_table.create_join(
            subquery.as(rank_table_alias),
            ::Arel::Nodes::On.new(
              model.arel_table.primary_key.eq(
                rank_table[:pg_search_id]
              )
            )
          )
        end

        def order_within_rank
          config.order_within_rank
        end

        def include_table_aliasing_for_rank(scope)
          return scope if scope.included_modules.include?(PgSearchRankTableAliasing)

          (::ActiveRecord::VERSION::MAJOR < 4 ? scope.scoped : scope.all.spawn)
            .instance_eval { extend(PgSearchRankTableAliasing) }
        end
    end
  end
end
