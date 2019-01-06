# frozen_string_literal: true

# Preload {Index#searchable} associations
#
# @see https://ksylvest.com/posts/2017-08-23/eager-loading-polymorphic-associations-with-ruby-on-rails
module PgMultisearch
  class Index::Relation::Preloader < ::BasicObject
    class << self
      # @param [ActiveRecord::Relation] relation
      #
      # @return [ActiveRecord::Relation]
      def call(relation)
        preloader(relation, :searchable).run

        relation.each do |result|
          type = type(result = referenced(result))

          preloadable?(associations = preloadable(type)) &&
            preloader(result, associations).run
        end

        relation
      end

      # @param [ActiveRecord::Relation] relation
      # @param [Array<Symbol, Hash>]
      #
      # @return [ActiveRecord::Associations::Preloader]
      def preloader(relation, associations)
        ::ActiveRecord::Associations::Preloader.new(
          relation,
          Array(associations)
        )
      end

      private

        # @param [PgMultisearch::Document] result
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
          type.pg_multisearch_options[:preloadable] || EMPTY_ARRAY
        end

        # @param [Array, Hash] A list of preloadable assocations
        #
        # @return [Boolean]
        def preloadable?(associations)
          associations.present?
        end
    end
  end
end
