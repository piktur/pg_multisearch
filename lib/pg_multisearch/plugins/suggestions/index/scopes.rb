# frozen_string_literal: true

module PgMultisearch
  module Suggestions::Index
    module Scopes
      def self.extended(base)
        base.scopes << :suggestions
      end

      # @example
      #   Index::Base.suggestions(input, limit: 5, type: 'Indexable')
      #
      # @yieldparam [ActiveRecord::Relation] scope
      #   Yields the current scope to the block
      # @yieldparam [Index::Relation] relation
      #   Yields the relation to the block
      #
      # @return [ActiveRecord::Relation]
      def suggestions(input, limit: 10, **options)
        options[:input] = input
        options[:limit] = limit

        build(Relation::Builder, __callee__, options) do |relation|
          # Preserve caller context, use `yield` rather than `#instance_eval`
          yield(relation.scope, relation) if block_given?
        end
      end
    end
  end
end
