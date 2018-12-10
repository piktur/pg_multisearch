# frozen_string_literal: true

module PgMultisearch
  module Relation
    extend ::ActiveSupport::Autoload

    autoload :Builder
    autoload :CollectionProxy
    autoload :Results
  end
end
