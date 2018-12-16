# frozen_string_literal: true

module PgMultisearch
  module Suggestions
    extend Plugin

    class << self
      def apply(*)
        super do
          %w(
            builder
            loader
            scope
          ).each { |f| require_relative "./suggestions/#{f}.rb" }

          ::PgMultisearch::Index.extend Scope
        end
      end
    end
  end
end
