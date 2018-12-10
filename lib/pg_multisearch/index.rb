# frozen_string_literal: true

module PgMultisearch
  class Index < ::ActiveRecord::Base
    include ::PgSearch

    self.table_name = 'pg_search_documents'

    # @!attribute [r] searchable
    #   @return [ActiveRecord::Base]
    belongs_to :searchable, polymorphic: true

    class << self
      # @example
      #   options = { ranked_by: 'ARRAY[:age, :tsearch]' }
      #   Index.search(query, type: 'SearchableType', **options) do |relation|
      #     relation
      #       .page(params[:page])
      #       .extending(::Search::Pagination)
      #   end
      #
      # @yieldparam [ActiveRecord::Relation] relation
      #
      # @return [ActiveRecord::Relation]
      def search(query, type: nil, preload: false, ranked_by: nil, **)
        return none if query.nil?

        builder = builder(
          query:     query,
          ranked_by: ranked_by
        )

        builder.apply(self).instance_eval do
          scope = self
          scope = scope.where(searchable_type: type.to_s) if type
          scope = scope.with_pg_search_rank
          scope = yield scope if block_given?
          scope = scope.order(builder.order_within_rank) if builder.order_within_rank

          if preload
            scope = scope.includes(:searchable)
            Preloader.call(scope)
          end

          scope
        end
      end

      private

        # @param [Hash] options Override {PgMultisearch.options}
        #
        # @return [ScopeOptions]
        def builder(options)
          Relation::Builder.new(config(options))
        end

        # @param (see #scope_options)
        #
        # @return [Configuration]
        def config(options)
          Configuration.new(
            {
              **::PgMultisearch.options,
              against: %i(content header),
              **options.reject { |k, v| v.nil? }
            },
            self
          )
        end
    end

    # @return [Float]
    def pg_search_rank
      self[:pg_search_rank]
    end
    alias rank pg_search_rank
  end
end

require_relative './relation/builder.rb'
