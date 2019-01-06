
# frozen_string_literal: true

module PgMultisearch
  module Configuration
    Indexable = ::Struct.new(
      :against,
      :additional_attributes,
      :index,
      :preloadable,
      :include_if,
      :exclude_if,
      :update_if
    ) do
      include Base

      class InvalidWeightError < ::StandardError
        def initialize(weight, weights)
          @weight  = weight
          @weights = weights
        end

        def message
          "'#{@weight}' is invalid. Use #{@weights.to_sentence(last_word_connector: ' or ')}"
        end
      end

      defaults do |obj|
        obj.additional_attributes = ::Set[]
        obj.exclude_if            = ::Set[]
        obj.include_if            = ::Set[]
        obj.preloadable           = []
        obj.update_if             = ::Set[]
      end

      # Add weighted attributes to {Indexable#searchable_text}.
      #
      # If block given, assigns the block under {#against} `weight` `attr`,
      # otherwise the `attr`.
      #
      # {Indexable#searchable_text} will yield the model to the block or call `attr` on the
      # model.
      #
      # @param [String] weight
      # @param [Symbol] attr
      # @param [Proc] block
      #
      # @yieldparam [ActiveRecord::Base] record
      def add(weight, attr, &block)
        meta.weights.include?(weight) || raise(InvalidWeightError, weight, meta.weights)

        against[weight.to_s][method = attr.to_sym] = block_given? ? block : method
      end

      def against
        fetch_or_store(:against) { meta.weights.map { |weight| [weight, {}] }.to_h }
      end

      # Declare additional values for {Index::Base} columns.
      #
      # The given `method` will be called against the model, or, if `method` nil and block given,
      # yields the model to the block.
      #
      # @yieldparam [ActiveRecord::Base] record
      # @yieldreturn [Hash{String=>Object}] A Hash containing column/value pair(s)
      def additional_attribute(method = nil, &block)
        additional_attributes << (method && method.to_sym || block)
      end

      def index=(klass)
        case klass
        when ::String then klass = ::Object.const_get(klass)
        when nil      then klass = Index::Base
        end

        self[:index] = klass
      end

      # @param [Symbol] method
      # @param [Proc] block
      def include_if(method = nil, &block)
        self[__callee__] << (method && method.to_sym || block)
      end
      alias_method :exclude_if, :include_if
      alias_method :update_if, :include_if

      # @return [Index::Meta]
      def meta
        index.meta
      end
    end
  end
end
