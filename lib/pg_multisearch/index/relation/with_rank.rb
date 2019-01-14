# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    # * {Base}
    # * {Threshold}
    # * {Polymorphic}
    module WithRank
      # @!attribute [rw] rank
      #   @return [Rank]
      attr_writer :rank

      # @!attribute [rw] rank_constructor
      #   @return [Proc]
      attr_accessor :rank_constructor

      def ranked?
        true
      end

      # @param (see Relation#call)
      #
      # @option [Symbol] options :order (:desc)
      #
      # @return [void]
      def apply(order: :desc, **options) # rubocop:disable MethodLength, AbcSize, CyclomaticComplexity
        super do
          yield(self) if block_given?

          rank.bind_params.offset = bind_params.count if rank.prepared_statement?

          order(
            Rank::RANK_ALIAS.send(order.to_sym),
            *order_within_rank(config.order_within_rank)
          )

          rank.call(options)

          # Use {#project_append} to ensure all columns referenced by the ranking strategies
          # are projected from filter_cte_table.
          project_append(*rank.columns_referenced_by_strategies)

          bind_params.merge(rank.bind_params) if rank.bind_params.present?
          projections.replace(projections | rank.projections)
          sources.replace(sources | rank.sources) if rank.sources.present?
          constraints.replace(constraints | rank.constraints) if rank.constraints.present?
          references.replace(references | rank.references) if rank.references.present?
        end
      end

      # @yieldparam [Relation] relation
      #
      # @return [Rank]
      def rank
        @rank ||= rank_constructor.call(self)
      end

      private

        # @param [Object] expression
        #
        # @yieldparam [ast.Table] source_table The table containing the filtered result set
        # @yieldreturn [ast.Node]
        #
        # @return [ast.Node]
        def order_within_rank(expression)
          case expression
          when ::Array then expression.flat_map { |e| order_within_rank(e) }
          when ::Proc  then order_within_rank(expression.call(filter_cte_table))
          else
            ast.nodes.node(expression) if expression
          end
        end
    end
  end
end
