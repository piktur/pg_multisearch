# frozen_string_literal: true

module PgMultisearch::Adapters
  module Sequel
    extend ::ActiveSupport::Autoload

    autoload :Functions
    autoload :Math
    autoload :Nodes
    autoload :SQL
  end
end
