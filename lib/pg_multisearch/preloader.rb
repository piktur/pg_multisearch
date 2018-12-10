# frozen_string_literal: true

# Preload {Index#searchable} associations
#
# @see https://ksylvest.com/posts/2017-08-23/eager-loading-polymorphic-associations-with-ruby-on-rails
class PgMultisearch::Preloader < BasicObject
  class << self
    # @param [ActiveRecord::Relation] relation
    #
    # @return [ActiveRecord::Relation]
    def call(relation)
      relation.each do |result|
        type = type(result = referenced(result))

        preloadable?(associations = preloadable(type)) &&
          ::ActiveRecord::Associations::Preloader.new(result, associations).run
      end

      relation
    end

    private

      # @param [PgSearch::Document] result
      #
      # @return [ActiveRecord::Base] The record associated with the `result`
      def referenced(result)
        result.searchable
      end

      # @param [ActiveRecord::Base] searchable
      #
      # @return [Class] The type of `searchable` model
      def type(searchable)
        searchable.class
      end

      # @param [Class] type
      #
      # @return [Array, Hash] A list of preloadable associations for `type`
      def preloadable(type)
        type.pg_search_multisearchable_options[:preloadable] || ::EMPTY_ARRAY
      end

      # @param [Array, Hash] A list of preloadable assocations
      #
      # @return [Boolean]
      def preloadable?(associations)
        associations.present?
      end
  end
end
