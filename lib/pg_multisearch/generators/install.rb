
# frozen_string_literal: true

module PgMultisearch::Generators
  module Install
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def exit_on_failure?
        true
      end
    end

    private

      def add_plugin_to_initializer(plugin, args = nil)
        inject_into_file(
          initializer_path,
          after: "PgMultisearch.configure do |options|\n"
        ) do
          <<-RUBY
"  plugin(:#{plugin}#{args ? ", #{args}": nil})\n"
          RUBY
        end
      end

      def inflector
        ::PgMultisearch.inflector
      end

      def initializer_path
        ::File.expand_path('config/initializers/pg_multisearch.rb', ::Rails.root)
      end

      def model_name
        @model_name ||= ::ActiveModel::Name.new(nil, nil, class_name)
      end

      def namespace
        @namespace ||= class_name.rpartition('::')[0]
      end

      def class_name
        @class_name ||= inflector.camelize(name)
      end

      def file_name
        "#{model_name.singular}.rb"
      end

      def class_path
        @class_path ||= inflector.underscore(namespace)
      end

      def model_path
        ::File.join('app', 'models', class_path, file_name)
      end
  end
end
