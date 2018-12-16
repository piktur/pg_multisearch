# frozen_string_literal: true

module PgMultisearch
  module Plugins
    extend ::ActiveSupport::Autoload

    autoload :Age
    autoload :Document
    autoload :Suggestions

    # @return [Hash]
    def plugins
      @plugins ||= {}
    end

    # @param [Symbol] plugin The plugin name
    # @param [Array<Object>] args
    # @param [Hash] options
    #
    # @return [void]
    def use(plugin, *args, &block)
      plugin = plugins[plugin]

      case plugin
      when ::Module           then handle_module(plugin, *args, &block)
      when ::String, ::Symbol then handle_name(plugin, *args, &block)
      when ::Proc             then handle_proc(plugin, *args, &block)
      end

      true
    end

    # @param [Symbol] plugin
    # @param [Module, String, Symbol, Proc] object
    #
    # @return [void]
    def register(plugin, object = nil, &block)
      plugins[plugin] = object || block

      true
    end

    private

      def handle_module(plugin, *args, &block)
        plugin.apply(*args, &block)
      end

      def handle_name(plugin, *args, &block)
        const  = ::ActiveSupport::Inflector.camelize(plugin)
        plugin = ::Object.const_get(const)

        handle_module(plugin, *args, &block)
      end

      def handle_proc(plugin, *args, &block)
        # plugin = plugin.arity.zero? ? plugin.call : plugin.call(*args, &block)
        plugin = plugin.call

        handle_module(plugin, *args, &block)
      end
  end
end
