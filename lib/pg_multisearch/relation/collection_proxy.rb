# frozen_string_literal: true

module PgMultisearch
  # Delegate pagination attributes to the{#relation}
  module Relation::CollectionProxy
    # @!attribute [r] relation
    #   @return [ActiveRecord::Relation]
    attr_accessor :relation

    # @return [ActiveRecord::Relation]
    def page
      relation.page
    end

    # @return [Integer]
    def current_page
      relation.current_page
    end

    # @return [Integer]
    def total_pages
      relation.total_pages
    end

    # @return [Integer]
    def limit_value
      relation.limit_value
    end

    # @return [Integer]
    def size
      relation.size
    end
    alias count size

    private

      def method_missing(method, *args)
        *args, include_private = args
        respond_to_missing?(method, include_private) && relation.send(method, *args) || super
      end

      def respond_to_missing?(method, include_private = false)
        relation.respond_to?(method) || super
      end
  end
end
