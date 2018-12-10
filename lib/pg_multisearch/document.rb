# frozen_string_literal: true

module PgMultisearch
  module Document
    extend ::ActiveSupport::Autoload

    autoload :Base
    autoload :Rank
    autoload :Rebuilder

    class << self
      # @example
      #   Search::Document[Person]
      #
      # @param [ActiveRecord::Base] model
      #
      # @yieldparam [Base] dfn
      #   Yields the Struct to given block.
      #
      # @return [Base]
      def call(model, &block)
        model.const_set :Document, ::Struct.new(:attributes, :rank) {
          include Base

          self.model = model

          block_given? && class_eval(&block)
        }

        defined?(::ActiveSupport::Dependencies) &&
          ::ActiveSupport::Dependencies.unloadable("#{model}::Document")

        model::Document
      end
      alias [] call
    end
  end
end
