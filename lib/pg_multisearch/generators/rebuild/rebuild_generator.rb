# frozen_string_literal: true

module PgMultisearch::Generators
  class Migration::RebuildGenerator < Migration
    source_root ::File.expand_path('templates', __dir__)

    ALIAS = '__searchable__'
    private_constant :ALIAS

    argument(
      :name,
      type:    :string,
      default: 'Search',
      banner:  'NAME',
      desc:    ''
    )

    class_option(
      :types,
      type:     :array,
      required: true,
      aliases:  '-t',
      banner:   '[ARRAY[STRING,]]',
      desc:     'A list of indexable Model(s)'
    )

    # @todo Replace types list
    def add_types
      model = ::PgMultisearch.inflector.camelize(name)
      path = "app/models/#{::PgMultisearch.inflector.underscore(name)}.rb"

      say_status(:warn, "Don't forget to update `#{model}.types` @ #{path}", :yellow)

      # gsub_file(
      #   model_path,
      #   /self\.types = \[\n(.*)\n\s+\]\n/m,
      # ) do
      #   options[:types].map { |type| "    ::#{inflector.camelize(type)}" }.join(",\n")
      # end
    end

    private

      def migration_name
        'rebuild_type_searchable'
      end

      def alias_existing
        format(read_sql_file(:alter_type_searchable), ruby: ALIAS)
      end

      def create_type(*values)
        format(read_sql_file(:create_type_searchable), ruby: values.join(', '))
      end

      def alter_typed_columns
        read_sql_file(:alter_table_pg_multisearch_index_searchable_type)
      end

      def drop_alias
        format(read_sql_file(:drop_type_searchable), ruby: ALIAS)
      end

      def old_values
        ::Search.types.map { |t| connection.quote(t.to_s) }
      end

      def new_values
        options[:types].map { |t| connection.quote(inflector.camelize(t)) }
      end
  end
end
