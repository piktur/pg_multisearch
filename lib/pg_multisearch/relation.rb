# frozen_string_literal: true

module PgMultisearch
  module Relation
    extend ::ActiveSupport::Autoload

    autoload :CollectionProxy
    autoload :Pagination
    autoload :Results
  end
end
