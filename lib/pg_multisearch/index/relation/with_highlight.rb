# frozen_string_literal: true

module PgMultisearch
  module Index::Relation::WithHighlight
    HIGHLIGHT_ALIAS = Adapters.ast.sql('pg_multisearch_highlight'.freeze).freeze

    # @return [void]
    def apply(*)
      super do
        yield(self) if block_given?

        if filter.highlight?
          select_append(
            index.projection(:data)
          )

          projections.push(
            ast.nodes.as(
              ast.nodes.group(filter.highlight),
              HIGHLIGHT_ALIAS
            )
          )
        end
      end
    end
  end
end
