# frozen_string_literal: true

module PgMultisearch
  class Index
    class Rebuilder
      include ::PgMultisearch::Arel

      # @!attribute [r] type
      #   @return [PgMultisearch::Indexable]
      attr_reader :type

      # @!attribute [r] target
      #   @return [Arel::Table]
      attr_reader :target

      # @param [PgMultisearch::Indexable] type
      # @param [Arel::Table] target
      def initialize(type, target = Index.arel_table)
        @type   = type
        @target = target
      end

      # @param [Indexable] object
      # @param [:insert, :update] command
      #
      # @return [Arel::InsertManager] if command :insert
      # @return [Arel::UpdateManager] if command :update
      def call(object, command:)
        case command
        when :insert then compile_insert(compile_select(object))
        when :update then compile_update(object)
        end
      end

      private

        # @return [Arel::Table]
        def source
          type.arel_table
        end

        # @return [Arel::SelectManager]
        def compile_select(object)
          select_manager = source.select_manager

          values, content = prepare(object)

          select_manager.project(
            *content.map { |(column, value)| as(value, column) },
            *values.map { |column, value| as(value, column) },
            as(::Arel.sql("'#{type}'::searchable"), 'searchable_type'),
            as(object.id, 'searchable_id')
          )

          select_manager
        end

        # @return [Arel::InsertManager]
        def compile_insert(select_manager)
          insert_manager = target.insert_manager
          insert_manager.into(target)
          insert_manager.insert(select_manager.to_sql)

          select_manager.projections.each do |column|
            insert_manager.columns << target[column.right]
          end

          insert_manager
        end

        # @return [Arel::UpdateManager]
        def compile_update(object)
          update_manager = ::Arel::UpdateManager.new(target.engine)
          update_manager.table(target)

          values, content = prepare(object)

          searchable_type = target[:searchable_type].eq(object.class.to_s)
          searchable_id   = target[:searchable_id].eq(object.id)

          tuple = lambda do |column, value|
            value = ::Arel.sql(value.to_sql) if value.is_a?(::Arel::Nodes::Node)

            [target[column], value]
          end

          update_manager.set([*content.map(&tuple), *values.map(&tuple)])
          update_manager.where(searchable_type.and(searchable_id))

          update_manager
        end

        def prepare(object)
          values = object.pg_search_document_attrs

          yield values if block_given?

          content = values.delete('content')

          [values, prepare_content(content)]
        end

        def prepare_content(content)
          content = cast_to_json(content)

          %w(content dmetaphone header).map do |column|
            fn = "pg_search_document_#{column}".to_sym

            [
              column,
              # ::Arel::SelectManager
              #   .new(::ActiveRecord::Base)
              #   .project(::Arel.star)
              #   .from(send(fn, content))
              send(fn, content)
            ]
          end
        end

        def cast_to_json(object)
          ::Arel.sql("$$#{::Oj.dump(object)}$$::jsonb")
        end

        def pg_search_document_content(content)
          fn('pg_search_document_content', [content])
        end

        def pg_search_document_dmetaphone(content)
          fn('pg_search_document_dmetaphone', [content])
        end

        def pg_search_document_header(content)
          fn('pg_search_document_header', [content])
        end

        def row_to_json(row)
          fn('row_to_json', [row])
        end
    end
  end
end
