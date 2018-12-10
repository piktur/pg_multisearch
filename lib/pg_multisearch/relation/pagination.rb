# frozen_string_literal: true

module PgMultisearch
  module Relation::Pagination
    def total_count
      loaded? ? length : super
    end
  end
end
