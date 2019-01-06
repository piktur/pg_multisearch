# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    # @see activerecord-4.0.13/lib/active_record/relation/calculations.rb
    #
    # @todo The temporary solution implemented within {Loader} should utilise this builder.
    #   Query fragments should be curried and applied only when necessary. They should be bound to
    #   the `ActiveRecod::Relation`.
    #
    # ```ruby
    #   index = PgMultisearch::Index::Base
    #   conn = index.connection
    #   table = index.arel_table
    #   expression = table.project(Arel.star.count)
    #
    #   index.count_by_sql(expression) # equivalent to `conn.select_value(expression, index.name)`
    # ```
    #
    # ```sql
    #   PREPARE c1 (text) AS
    #   WITH
    #     q AS (
    #       SELECT
    #         to_tsquery('english', unaccent($1)) AS tsearch,
    #         dmetaphone_to_tsquery(string_to_dmetaphone(unaccent($1))) AS dmetaphone
    #     ),
    #     pg_multisearch_5cf74631104e9e5a0 AS (
    #       SELECT
    #         "pg_multisearch_index"."id",
    #         "pg_multisearch_index"."content",
    #         "pg_multisearch_index"."dmetaphone"
    #       FROM
    #         q,
    #         "pg_multisearch_index"
    #       WHERE (
    #         (("pg_multisearch_index"."content") @@ ("q"."tsearch"))
    #         OR
    #         (("pg_multisearch_index"."dmetaphone") @@ ("q"."dmetaphone"))
    #       )
    #     )
    #   SELECT
    #     COUNT("pg_multisearch_5cf74631104e9e5a0"."id")
    #   FROM
    #     "pg_multisearch_5cf74631104e9e5a0";
    #
    #   EXECUTE c1 ('Eaton & Vance');
    # ```
    class Count
      include ::PgMultisearch.adapter

      class << self
        # @return [Array<Rank::Base>]
        #   A list of classes where rank MUST NOT BE removed from the SELECT statement.
        def rank_contingent_classes
          @rank_contingent_classes ||= []
        end

        # Register rank contingent classes
        #
        # @param [Array<Class>]
        #
        # @return [void]
        def rank_contingent(*klass)
          rank_contingent_classes.push(*klass)
        end
      end

      # @!attribute [r] relation
      #   @return [Relation]
      attr_reader :relation

      # @!attribute [r] index
      #   @return [Index::Base]
      attr_reader :index

      # @!attribute [r] sources
      #   @return [Array<ast.Node>]
      attr_reader :sources

      # @!attribute [r] with_values
      #   @return [Array<ast.Node>]
      attr_accessor :with_values

      # @param [Relation] relation
      def initialize(relation)
        @relation = relation
        @index    = relation.index

        extend(prepared_statement? ? AsPreparedStatement : AsStatement)

        @with_values = []
        @sources     = []
      end

      # @return [self]
      def call(*)
        apply

        yield(self) if block_given?

        self
      end

      # @return [void]
      def apply(*)
        if rank_contingent?
          raise ::NotImplementedError

          # Remove unnecessary projections
          # Remove orders
          # Remove limit
          # Remove offset
          # Wrap the query and project count
        end

        with_values.replace([query_cte_alias, filter_cte_alias])
        sources.replace([filter_cte_table])

        @bind_params = relation.bind_params.dup

        bind_params.delete(:limit)
        bind_params.delete(:offset)

        @expression = expression
      end

      # @return [Boolean]
      def rank_contingent?
        self.class.rank_contingent_classes.any? { |klass| relation.ranked_with?(klass) }
      end

      # @return [ast.SelectManager]
      def expression
        ast.select_manager(index, filter_cte_table)
          .with(with_values)
          .from(sources)
          .project(projections.to_a)
          .take(nil)
          .skip(nil)
      end

      # @return [Projections]
      def projections
        @projections ||= Projections.new(
          filter_cte_table,
          count
        )
      end

      private

        def count
          ast.star.count
        end

        def filter_cte_table
          relation.filter_cte_table
        end

        def filter_cte_alias
          relation.filter_cte_alias
        end

        def query_cte_alias
          relation.query_cte_alias
        end

        def prepared_statement?
          relation.prepared_statement?
        end

        def config
          relation.config
        end
    end
  end
end
