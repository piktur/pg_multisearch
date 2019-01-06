# frozen_string_literal: true

module PgMultisearch
  # @todo Replace Arel with abstract AST method
  class Index::Rebuilder
    include ::PgMultisearch.adapter

    # @!attribute [r] type
    #   @return [PgMultisearch::Indexable]
    attr_reader :type

    # @!attribute [r] index
    #   @return [Index::Base]
    attr_reader :index

    # @!attribute [r] target
    #   @return [ast.Table]
    attr_reader :target

    # @param [PgMultisearch::Indexable] indexable
    def initialize(indexable)
      @type   = indexable
      @index  = indexable.pg_multisearch_index
      @target = ast.table(index.table_name, index) # index.arel_table
    end

    # @param [Indexable] object
    # @param [Hash] options
    #
    # @option [:insert, :update] options :command
    # @option [Array<String>] options :weights
    #
    # @return [Arel::InsertManager] if command :insert
    # @return [Arel::UpdateManager] if command :update
    def call(object, command:, **options)
      case command
      when :insert then compile_insert(compile_select(object, options))
      when :update then compile_update(object, options)
      end
    end

    protected

      # @return [ast.SqlLiteral]
      def indexable_type
        index.projection(:searchable_type)
      end

      # @return [ast.SqlLiteral]
      def indexable_id
        index.projection(:searchable_id)
      end

    private

      # @return [ast.Table]
      def source
        @source ||= ast.table(type.table_name, type) # type.arel_table
      end

      # Refresh table stats after batch INSERT/UPDATE/DELETE
      #
      # @return [ast.SqlLiteral]
      def analyze
        ast.sql("ANALYZE #{target.table_name};")
      end

      # @param [ActiveRecord::Base] object
      # @param [Hash] options
      #
      # @return [ast.SelectManager]
      def compile_select(object, **options)
        select_manager = source.select_manager

        values, content = prepare(object, options)

        select_manager.project(
          *content.map { |(column, value)| ast.nodes.as(value, column) },
          *values.map { |column, value| ast.nodes.as(value, column) },
          ast.nodes.as(ast.sql("'#{type}'::searchable"), indexable_type),
          ast.nodes.as(object.id, indexable_id)
        )

        select_manager
      end

      # @param [ast.SelectManager] select_manager
      #
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

      # @param [ActiveRecord::Base] object
      # @param [Hash] options
      #
      # @return [Arel::UpdateManager]
      def compile_update(object, **options)
        update_manager = ::Arel::UpdateManager.new(target.engine)
        update_manager.table(target)

        values, content = prepare(object, options)

        tuple = lambda do |column, value|
          value = ast.sql(value.to_sql) if value.is_a?(ast.Node)

          [target[column], value]
        end

        update_manager.set([*content.map(&tuple), *values.map(&tuple)])
        update_manager.where(
          target[indexable_type].eq(object.class.to_s)
            .and(target[indexable_id].eq(object.id))
        )

        update_manager
      end

      def prepare(object, **options)
        values = object.pg_multisearch_document_attrs

        yield values if block_given?

        content = values.delete('content')

        [values, prepare_content(content, **options)]
      end

      def prepare_content(content, **options)
        content = cast_to_json(content)

        index.projections(:tsearch, :dmetaphone, :trigram).map do |column|
          fn = "pg_multisearch_#{column}".to_sym

          [column, send(fn, content, options)] # ast.fn.send(fn, content, options)
        end
      end

      # @todo Reconsider configuration object to refence; should we use the global config or that
      #   of the {#index}?
      def config
        index.config.search
      end

      def cast_to_json(object)
        ast.sql("$$#{::Oj.dump(object)}$$::jsonb")
      end

      def weights(weights)
        ast.sql("'{#{Array(weights).join(',')}}'::text[]")
      end

      def pg_multisearch_content(
        content,
        weights: config.dig(:strategies, :tsearch, :weights) { Index.meta.weights },
        **
      )
        ast.nodes.fn(
          'pg_multisearch_content'.freeze,
          [
            content,
            weights(weights)
          ]
        )
      end

      def pg_multisearch_dmetaphone(
        content,
        weights: config.dig(:strategies, :dmetaphone, :weights) { Index.meta.weights[0] },
        **
      )
        ast.nodes.fn(
          'pg_multisearch_dmetaphone'.freeze,
          [
            content,
            weights(weights)
          ]
        )
      end

      def pg_multisearch_trigram(
        content,
        weights: config.dig(:strategies, :trigram, :weights) { Index.meta.weights[0] },
        **
      )
        ast.nodes.fn(
          'pg_multisearch_trigram'.freeze,
          [
            content,
            weights(weights)
          ]
        )
      end
  end
end
