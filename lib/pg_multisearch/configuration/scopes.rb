# frozen_string_literal: true

module PgMultisearch
  module Configuration
    module Scopes
      module InstanceMethods
        # @return [Configuration::Options]
        def defaults
          ::PgMultisearch.config
        end

        def to_hash
          h = {}
          members.each { |k| (v = self[k]) && h[k] = v.to_h }
          h
        end
        alias to_h to_hash
      end

      # @param [Index::Base] index
      #
      # @return [Struct]
      def self.[](index) # rubocop:disable MethodLength, AbcSize
        ::Struct.new(*index.scopes) do
          include Base
          include InstanceMethods

          index.scopes.each do |scope|
            class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              # @return [Configuration::Options]
              def #{scope}(&block)
                fetch_or_store(:#{scope}) { Options.new(index: #{index}, __meta__: __meta__) }
                  .tap { |obj| yield(obj, __meta__) if block_given? } | defaults
              end

              # Replaces the value with a new instance. Defaults WILL NOT be applied.
              #
              # @yieldparam [Options] options
              # @yieldparam [Options] defaults
              # @yieldparam [Index::Meta] index
              #
              # @return [Configuration::Options]
              def #{scope}!
                obj = Options.new(__meta__: __meta__)

                yield(obj, defaults, __meta__) if block_given?

                self[:#{scope}] = obj
              end
            RUBY
          end
        end.tap do |dfn|
          Configuration.const_set(index.name.gsub(/::/, '_').to_sym, dfn)

          defined?(::ActiveSupport::Dependencies) &&
            ::ActiveSupport::Dependencies.unloadable(dfn.name)
        end
      end
    end
  end
end
