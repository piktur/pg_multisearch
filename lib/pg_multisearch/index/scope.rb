# frozen_string_literal: true

module PgMultisearch
  class Index
    # Materializes the relation and decorates the denormalized data for each result.
    module Scope
      # @example
      #   options = { ranked_by: ':tsearch' }
      #   Index.search(query, type: 'SearchableType', **options) do |relation|
      #     relation
      #       .page(params[:page])
      #       .extending(::Search::Pagination)
      #   end
      #
      # @yieldparam [ActiveRecord::Relation] relation
      # @yieldparam [Builder] builder
      #
      # @return [ActiveRecord::Relation]
      def search(
        query,
        type: nil,
        builder: Builder,
        **options,
        &block
      )
        build(
          builder,
          query: query,
          **options
        ) do |scope, builder|
          scope = scope.with_pg_search_rank
          scope = scope.where(searchable_type: type.to_s) if type

          # Preserve caller context, use `yield` rather than `#instance_eval`
          scope = yield scope, builder if block_given?

          scope
        end
      end

      protected

        # @param [Builder] builder
        # @param [Hash] options Override {PgMultisearch.options}
        #
        # @return [ScopeOptions]
        def build(builder, preload: false, **options, &block)
          builder
            .new(config(options))
            .apply(self, preload: preload, &block)
        end

        # @param (see #scope_options)
        #
        # @return [Configuration]
        def config(options)
          Configuration.new(
            {
              **::PgMultisearch.options,
              **options.reject { |k, v| v.nil? }
            },
            self
          )
        end
    end
  end
end
