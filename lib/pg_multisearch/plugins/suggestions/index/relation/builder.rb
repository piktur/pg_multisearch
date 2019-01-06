# frozen_string_literal: true

module PgMultisearch
  class Suggestions::Index::Relation::Builder < Index::Relation::Builder
    def call(current_scope, **options)
      super do |relation|
        relation.select_append(
          *index.projections(
            :searchable_type,
            :searchable_id,
            :data
          )
        )

        yield(relation) if block_given?
      end
    end
  end
end
