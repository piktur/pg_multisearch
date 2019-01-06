# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    # Applies query fragments to the current scope.
    #
    # @todo Adapters should implement their own merge strategies. This will do for ActiveRecord
    #   and Arel.
    # @todo Transfer to the adapter namespace.
    #
    # @see Count
    # @see activerecord/lib/active_record/relation/query_methods.rb
    #   ActiveRecord::Relation::QueryMethods#build_arel
    module Merge
      include ::PgMultisearch.adapter

      class << self
        # @param [Relation] left
        # @param [ActiveRecord::Relation, ast.SelectManager] right
        #
        # @return [Array<ast.SelectManager>] Applies `left` to `right`
        def call(left, right, adapter: :arel, **options)
          case adapter
          when :active_record then active_record(left, right, options)
          when :arel          then arel(left, right, options)
          end
        end
        alias [] call

        private

          # @todo `!` methods apply transformations to the receiver;
          #   not a clone as non-bang methods do. Of course this is somewhat faster than `spawn`;
          #   there may be side-effects.
          #
          # @param [Relation] left
          # @param [ActiveRecord::Relation] right
          #
          # @return [ActiveRecord::Relation]
          def active_record(left, right, preload: false, **) # rubocop:disable AbcSize, MethodLength
            right = right
              .extend(WithCTE)
              .extend(WithLimitBind)
              .extend(WithOffsetBind)
              .extend(WithCount)
              .readonly!
              .with!(left.with_values)
              ._select!(*left.projections | named_projections(right.select_values))
              .from!(left.sources)

            # @todo This mightn't be the most appropriate way to handle bind parameters?
            right = left.bind_params.reduce(right) { |scope, value| scope.bind!(value) }
            right = right.where!(left.constraints.reduce(&:and)) if left.constraints.present?
            right = right.order!(*left.orders) if left.orders.present?
            right = right.limit!(left.limit) if left.limit
            right = right.offset!(left.offset) if left.offset

            # Qualify CTE references
            right = right.references!(*left.references) if preload

            right
          end

          # @param [Relation] left
          # @param [Arel::SelectManger] right
          #
          # @return [Arel::SelectManger]
          def arel(left, right, **) # rubocop:disable AbcSize
            right.with(left.with_values)
            right.projections = (left.projections | named_projections(right.projections))
            right.from(left.sources)
            right.where(left.constraints.reduce(&:and)) if left.constraints.present?
            right.order(*left.orders)
            right.take(left.limit)
            right.skip(left.offset)

            right
          end

          # @param [Array<ast.Attribute, String>]
          #
          # @return [Array<ast.Attribute, String>] Removes any projections matching `*`
          def named_projections(projections)
            projections.reject do |e|
              case e
              when ast.Attribute then e.name == ast.star
              when ::String      then e.end_with?(ast.star)
              end
            end
          end

          # @return[ast.SelectManager]
          def self.select_manager(engine, table)
            ast.select_manager(engine, table)
          end
      end
    end
  end
end
