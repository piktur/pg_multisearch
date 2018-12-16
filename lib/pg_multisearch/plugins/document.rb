# frozen_string_literal: true

module PgMultisearch
  # Denormalization avoids unnecessary joins and should improve query performance significantly.
  # Use {Document::base} to decorate results and avoid ActiveRecord bloat.
  #
  # | Column     | Type     | Description                                                         |
  # |------------|----------|---------------------------------------------------------------------|
  # | content    | tsvector | An aggregation of searchable attributes grouped by weight           |
  # | header     | text     |                                                                     |
  # | data       | jsonb    | A denormalized copy of the data necessary to render a result (JSON) |
  module Document
    extend ::ActiveSupport::Autoload

    autoload :AsDocument, 'pg_multisearch/plugins/document/as_document'
    autoload :Base,       'pg_multisearch/plugins/document/base'
    autoload :Rebuilder,  'pg_multisearch/plugins/document/rebuilder'

    extend Plugin

    DATA_COLUMN = 'data'

    class << self
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
          %w(
            builder
            indexable
            loader
            scope
          ).each { |f| require_relative "./document/#{f}.rb" }

          ::PgMultisearch::Indexable.extend Indexable
          ::PgMultisearch::Index.extend Scope
        end
      end
    end
  end
end
