# frozen_string_literal: true

module PgMultisearch
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Install

      UNREGISTERED_PLUGIN = 'Unrecognised plugin: `%{plugin}`. Use %{plugins}'

      source_root ::File.expand_path('templates', __dir__)

      argument(:name, type: :string, default: 'Search')

      class_option(
        :use,
        type:    :string,
        aliases: '-p',
        banner:  '[JSON]',
        desc:    'Install and configure plugins'
      )

      class_option(
        :types,
        type:     :array,
        required: true,
        aliases:  '-t',
        banner:   '[ARRAY[STRING,]]',
        desc:     'A list of searchable Model(s)'
      )

      def self.plugins
        @plugins ||= ::PgMultisearch.plugins.keys
      end

      def create_migration
        invoke(Migration::IndexGenerator)
      end

      def create_model
        template 'app/models/model.rb.erb', model_path
      end

      def install_plugins
        return unless options[:use]

        plugins = ::Oj.load(options[:use], symbol_keys: true)

        plugins.each do |plugin, args|
          install(plugin, args == true ? EMPTY_HASH : args)
        end
      end

      private

        def install(plugin, args)
          registered!(plugin)

          require ::File.join('pg_multisearch', 'plugins', plugin.to_s)
          require ::File.join('pg_multisearch', 'plugins', generator_path(plugin, 'install'))

          invoke(generator(plugin, 'install'), nil, args)
        end

        def generator(plugin, name)
          const = inflector.camelize("#{plugin}/generators/#{name}_generator")
          ::PgMultisearch.const_get(const, false)
        end

        def generator_path(plugin, name)
          ::File.join(plugin.to_s, 'generators', name.to_s, "#{name}_generator")
        end

        def registered!(plugin)
          return true if plugin?(plugin)

          msg = format(UNREGISTERED_PLUGIN, plugin: plugin, plugins: plugins.join(', '))

          say_status(:error, :red, msg) { raise Error }
        end

        def plugins
          self.class.plugins
        end

        def plugin?(plugin)
          plugins.include?(plugin.to_sym)
        end
    end
  end
end
