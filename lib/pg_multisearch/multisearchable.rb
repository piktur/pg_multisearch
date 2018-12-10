# frozen_string_literal: true

require_relative './multisearchable/document.rb'

module PgMultisearch
  # `PgSearch#multisearchable` does not honour attribute weight. Multisearchable reimplements
  # `PgSearch::Multisearchable#pg_search_document_attrs` allowing indexed data to be weighted.
  #
  # Denormalization avoids unnecessary joins and should improve query performance significantly.
  # Use {Document} to decorate results and avoid ActiveRecord bloat.
  #
  # | Column     | Type     | Description                                                         |
  # |------------|----------|---------------------------------------------------------------------|
  # | content    | jsonb    | An aggregation of searchable attributes grouped by weight           |
  # | data       | jsonb    | A denormalized copy of the data necessary to render a result (JSON) |
  # | provenance | datetime | A date by which this document should be ranked when sorted by age   |
  module Multisearchable
    extend ::ActiveSuport::Autoload

    autoload :AsDocument
    autoload :Document

    def self.included(base)
      base.include ::PgSearch
      base.prepend Document
      base.include AsDocument
    end
  end
end
