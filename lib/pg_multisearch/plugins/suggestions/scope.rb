# frozen_string_literal: true

module PgMultisearch
  module Suggestions
    module Scope
      # @return [Hash]
      def self.defaults
        @defaults ||= {}
      end

      defaults[:against] = [Index::HEADER_COLUMN]
      defaults[:ranked_by] = ':trigram'
      defaults[:using] = {
        trigram: {
          **Suggestions.options[:using][:trigram],
          only: Index::HEADER_COLUMN
        }
      }

      # @example
      #   Index.suggestions(query, limit: 5, type: 'Indexable')
      #
      # @return [ActiveRecord::Relation]
      def suggestions(query, limit: 10, type: nil, **options) # rubocop:disable MethodLength
        return none if query.nil?

        build(
          Suggestions::Builder,
          **Suggestions::Scope.defaults,
          query: query,
          **options
        ) do |scope|
          scope = scope.limit(limit)
          scope = scope.where(searchable_type: type.to_s) if type

          scope
        end
      end
    end
  end
end
