# frozen_string_literal: true

module PgMultisearch
  class Index
    # @see file:lib/tasks.rb
    class Rebuild
      class DisabledError < ::StandardError
        def initialize(model)
          @model = model
        end

        def message
          "PgMultisearch is not enabled: #{@model}. `include #{Indexable}` to enable."
        end
      end

      def initialize(model, options = EMPTY_HASH)
        @model = model

        call(options)
      end

      # @todo Implement multi insert
      def call(clean: true, **)
        raise DisabledError.new(model) unless model < Indexable

        model.transaction do
          Index.where(searchable_type: model.base_class.name).delete_all if clean

          if model.respond_to?(:rebuild_pg_search_documents)
            model.rebuild_pg_search_documents
          elsif conditional? || dynamic?
            model.find_each { |record| record.update_pg_search_document }
          else
            model.includes(preloadable).find_each do |record|
              connection.execute(
                model.pg_multisearch_rebuilder.call(record, command: :insert).to_sql
              )
            end
          end
        end
      end

      private

        attr_reader :model

        def conditional?
          %i(if unless).any? { |key| model.pg_multisearch_options.key?(key) }
        end

        def dynamic?
          columns.any? { |column| !model.column_names.include?(column.to_s) }
        end

        def columns
          Array(model.pg_multisearch_options[:against])
        end

        def preloadable
          model.pg_multisearch_options[:preloadable] || EMPTY_ARRAY
        end

        def connection
          model.connection
        end
    end
  end
end
