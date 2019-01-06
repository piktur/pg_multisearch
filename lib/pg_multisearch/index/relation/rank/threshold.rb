# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    # Calculates {#primary} rank then, if less than {#threshold}, calculates {#secondary} rank.
    class Rank::Threshold < Rank::Base
      PRIMARY_RANK = ast.sql('r1'.freeze).freeze
      SECONDARY_RANK = ast.sql('r2'.freeze).freeze

      Count.rank_contingent(self)

      # @!attribute [rw] threshold
      #   @return [Float]
      attr_reader :threshold

      # @param [Float] float
      def threshold=(float)
        @threshold = float.to_f
      end

      # @option [Float] options :threshold (1e-20)
      def initialize(*, threshold: 1e-20, **)
        super

        @primary, @secondary = strategies
        self.threshold = threshold

        @constraints = []
      end

      # @option [Float] options :threshold (1e-20)
      #   Accepts threshold - this value may change at runtime
      #   ie. the application allows the user to refine the result set accepting an arbitrary
      #   threshold
      #
      # @return [void]
      def apply(threshold: nil, **) # rubocop:disable AbcSize
        threshold = bind(:threshold, threshold ? self.threshold = threshold : self.threshold)

        projections << rank
        sources.replace([primary_rank, secondary_rank] | sources)
        constraints.replace([ast.math.gt(SECONDARY_RANK, threshold)] | constraints)
        references.replace([PRIMARY_RANK, SECONDARY_RANK] | references)
      end

      # @return [as.Node]
      def rank
        @rank ||= ast.nodes.as(SECONDARY_RANK, RANK_ALIAS)
      end

      def inspect
        "#{a = primary.strategy_name} > #{threshold} ? #{a} : #{secondary.strategy_name}"
      end

      private

        # @return [ast.TableAlias]
        def primary_rank
          primary_expression.left = ast.nodes.lateral(primary.rank)
          primary_expression
        end

        # @return [ast.TableAlias]
        def primary_expression
          @primary_expression ||= ast.nodes.table_alias(nil, PRIMARY_RANK)
        end

        # @param [Float] threshold
        #
        # @return [ast.TableAlias]
        def secondary_rank(threshold) # rubocop:disable AbcSize
          expression = ast.nodes.table_alias(secondary_case(threshold), SECONDARY_RANK)
          secondary_expression.projections[0] = expression

          ast.nodes.table_alias(
            ast.nodes.lateral(ast.nodes.group(secondary_expression)),
            SECONDARY_RANK
          )
        end

        # @return [ast.Node]
        def secondary_expression
          @secondary_expression ||= ast.nodes.select
        end

        # @return [ast.Node]
        def secondary_case(threshold)
          ast.nodes.case(
            [[secondary_condition(threshold), PRIMARY_RANK]],
            nil,
            secondary.rank
          )
        end

        # @return [ast.Node]
        def secondary_condition(threshold)
          ast.math.gt(PRIMARY_RANK, threshold)
        end
    end
  end
end
