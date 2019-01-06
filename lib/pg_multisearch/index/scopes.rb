# frozen_string_literal: true

module PgMultisearch
  module Index
    # Materializes the relation and decorates the denormalized data for each result.
    module Scopes
      def self.extended(base)
        base.scopes.merge %i(search with_rank_gt)
      end

      # @yieldparam [Configuration::Scopes] config
      # @yieldparam [Index::Base] index
      #
      # @return [Configuration::Scopes]
      def configure
        @config = Configuration::Scopes[self].new(__meta__: meta)
          .tap { |obj| yield(obj, meta) if block_given? }
          .finalize!
      end

      # @return [Configuration::Scopes]
      def config
        @config ||= Configuration::Scopes[self].new(__meta__: meta)
      end

      # @example
      #   Index::Base.search(input, **options)
      #
      # @param [String] input The unsanitized search phrase
      # @param [Hash] options
      #
      # @option [Relation::Builder] options :builder (Relation::Builder)
      # @option [Integer] options :limit
      # @option [Symbol] options :order
      # @option [Integer] options :page
      # @option [Boolean] options :preload
      # @option [String] options :type
      #
      # @yieldparam [ActiveRecord::Relation] scope
      #   Yields the current scope to the block
      # @yieldparam [Index::Relation] relation
      #   Yields the relation to the block
      #
      # @return [ActiveRecord::Relation]
      def search(input, builder: Relation::Builder, **options)
        options[:input] = input

        build(builder, __callee__, options) do |relation|
          # Preserve caller context, use `yield` rather than `#instance_eval`
          yield(relation.scope, relation) if block_given?
        end
      end

      # @param (see #search)
      #
      # @option [Float] options :threshold
      #
      # @return [ActiveRecord::Relation]
      def with_rank_gt(input, **options, &block)
        search(input, **options, &block)
      end

      # @param [Symbol] scope_name
      #
      # @return [Configuration::Base]
      def scope_config(scope_name)
        config.send(scope_name)
      end

      protected

        # @param [Builder] builder
        # @param [Symbol] scope_name
        # @param [Hash] options
        #
        # @return [Builder]
        if ::ActiveRecord::VERSION::MAJOR < 4
          def build(builder, scope_name, options, &block)
            builder(builder, scope_name).call(scoped, options, &block)
          end
        else
          def build(builder, scope_name, options, &block)
            builder(builder, scope_name).call(all, options, &block)
          end
        end

        # @todo The {#hash} of run time `options` COULD BE used as a cache key if they are
        #   sufficiently unique.
        #
        # @return [Integer] A unique identifier used to cache the relation
        # def hash
        #   options.hash
        # end

        # @return [Builder]
        def builder(builder, scope_name)
          # cache[builder, scope_name] ||= builder.new(scope_config(scope_name))
          builder.new(scope_config(scope_name))
        end

      private

        # @todo Clear on reload!
        # @todo Implement cache mechanism utilising `Concurrent::Map`
        #
        # @return [Cache]
        def cache
          @cache ||= Cache.new
        end
    end
  end
end
