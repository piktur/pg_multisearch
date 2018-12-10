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
      # @return [ActiveRecord::Relation]
      def search(query, type: nil, preload: false, ranked_by: ':age', **)
        return none if query.nil?

        scope_options(
          query:     query,
          ranked_by: ranked_by
        ).apply(self).instance_eval do
          where(searchable_type: type.to_s) if type

          yield with_pg_search_rank if block_given?

          Preloader.call(self) if preload

          self
        end
      end

      private
        
        def scope_options(options)
          ScopeOptions.new(config(options))
        end

        def config(options)
          Configuration.new(
            {
              **::PgMultisearch.options,
              against: %i(content header),
              **options
            },
            self
          )
        end
    end
  end
end
