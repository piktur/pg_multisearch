# frozen_string_literal: true

module PgMultisearch
  # Denormalization avoids unnecessary joins and should improve query performance significantly.
  # Use {Document::Base} to decorate results and avoid `ActiveRecord` bloat.
  #
  # | Column     | Type     | Description                                                         |
  # |------------|----------|---------------------------------------------------------------------|
  # | content    | tsvector | An aggregation of searchable attributes grouped by weight           |
  # | trigram    | text     |                                                                     |
  # | dmetaphone | text     |                                                                     |
  # | data       | jsonb    | A denormalized copy of the data necessary to render a result (JSON) |
  module Document
    extend ::ActiveSupport::Autoload

    autoload :AsDocument, 'pg_multisearch/plugins/document/as_document'
    autoload :Base,       'pg_multisearch/plugins/document/base'
    autoload :Index,      'pg_multisearch/plugins/document/index'
    autoload :Indexable,  'pg_multisearch/plugins/document/indexable'
    autoload :Search,     'pg_multisearch/plugins/document/search'

    extend Plugin

    class << self
      def plugin_name
        :document
      end

      # @example
      #   Search::Document[Person]
      #
      # @param [ActiveRecord::Base] model
      #
      # @yieldparam [Base] dfn
      #   Yields the Struct to given block.
      #
      # @return [Base]
      def call(model, &block)
        model.const_set(:Document, ::Struct.new(:attributes, :rank) {
          include Base

          self.model = model

          block_given? && class_eval(&block)
        }).tap do
          defined?(::ActiveSupport::Dependencies) &&
            ::ActiveSupport::Dependencies.unloadable("#{model}::Document")
        end
      end
      alias [] call

      def apply(*) # rubocop:disable MethodLength
        super do
          ::PgMultisearch::Index::Base.projections[:data] = 'data'
          ::PgMultisearch::Index::Base.extend(Index::Scopes)
          ::PgMultisearch::Index::Base.include(Index::AsDocument)
          ::PgMultisearch::Indexable.extend(Indexable)
          ::PgMultisearch::Search.prepend(Search)
        end
      end
    end
  end
end
