# frozen_string_literal: true

module PgMultisearch
  # @see file:lib/tasks.rb
  class Index::Rebuild
    class DisabledError < ::StandardError
      def initialize(indexable)
        @indexable = indexable
      end

      def message
        "#{@indexable} is not indexable. `#{@indexable}.include(#{Indexable})` to enable."
      end
    end

    # @param [ActiveRecord::Base] indexable
    # @param [Hash] options
    #
    # @option [Boolean] options :clean (true)
    def initialize(indexable, options = EMPTY_HASH)
      @indexable = indexable
      @index     = indexable.pg_multisearch_index

      call(options)
    end

    # @todo Implement multi insert
    def call(clean: true, **)
      raise DisabledError, indexable unless indexable < Indexable

      indexable.transaction do
        index.where(searchable_type: indexable.base_class.name).delete_all if clean

        if indexable.respond_to?(:rebuild_pg_multisearch_documents)
          indexable.rebuild_pg_multisearch_documents
        elsif conditional? || dynamic?
          indexable.find_each(&:update_pg_multisearch_document)
        else
          indexable.includes(preloadable).find_each do |record|
            connection.execute(
              indexable.pg_multisearch_rebuilder.call(record, command: :insert).to_sql
            ).clear
          end
        end
      end
    end

    private

      attr_reader :indexable

      def conditional?
        %i(if unless).any? { |key| indexable.pg_multisearch_options.key?(key) }
      end

      def dynamic?
        columns.any? { |column| !indexable.column_names.include?(column.to_s) }
      end

      def columns
        Array(indexable.pg_multisearch_options[:against])
      end

      def preloadable
        indexable.pg_multisearch_options[:preloadable] || EMPTY_ARRAY
      end

      def connection
        indexable.connection
      end
  end
end
