# frozen_string_literal: true

module PgMultisearch
  class Document::Index::Relation::Builder < Index::Relation::Builder
    def call(current_scope, **options)
      super do |relation|
        relation.select_append(
          *index.projections(
            :data
          )
        )

        yield(relation) if block_given?
      end
    end
  end
end
