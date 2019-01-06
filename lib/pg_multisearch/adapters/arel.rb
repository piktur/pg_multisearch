# frozen_string_literal: true

module PgMultisearch::Adapters
  module Arel
    extend ::ActiveSupport::Autoload

    autoload :Functions
    autoload :Math
    autoload :Nodes
    autoload :SQL

    require_relative './arel/compatibility.rb' if ::ActiveRecord::VERSION::MAJOR < 5
  end
end
