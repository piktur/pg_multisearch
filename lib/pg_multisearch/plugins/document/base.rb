# frozen_string_literal: true

module PgMultisearch
  # A Document is a lightweight data struct. It encapsulates denormalized data and
  # performs type coercion necessary to render a {Search#result}.
  #
  # A Document SHOULD implement all attributes and methods of the represented {#model}
  # to be called within a view; the view SHOULD NOT be aware of the difference between a Document
  # and an ActiveRecord.
  module Document::Base
    def self.included(base)
      base.include ::ActiveModel::Conversion
      base.extend  ClassMethods
      base.include InstanceMethods
    end

    module InstanceMethods
      # @!attribute [r] attributes
      #   @return [Hash{Symbol => Object}]
      attr_reader :attributes

      # @!attribute [r] attributes
      #   @return [Array<Symbol>]
      attr_reader :attribute_names

      # @!attribute [r] rank
      #   @return [Float]
      attr_accessor :rank

      # @param [Hash, String] attributes
      # @param [Float] rank
      # @param [String] highlight
      def initialize(attributes = {}, rank = 0.0, highlight = nil)
        attributes = case attributes
        when ::String then ::Oj.load(attributes, symbol_keys: true)
        when ::Hash   then attributes.deep_symbolize_keys
        else {}
        end

        attributes[:__id__]        = attributes[:__id__].to_i if attributes.key?(:__id__)
        attributes[:__highlight__] = highlight

        super(attributes, rank.to_f)

        @attribute_names = attributes.keys
      end

      # @example
      #   Document = Struct.new(:attributes) do
      #     alias_method :name, :attribute
      #   end
      #   doc = Document.new(name: 'Someone')
      #   doc.name # => 'Someone'
      #
      # @return [Symbol] key The value assigned to {#__callee__}
      #
      # @return [Object]
      def attribute
        attributes[__callee__]
      end

      # @!attribute [r] __type__
      #   @return [String]
      alias __type__ attribute

      # @!attribute [r] __id__
      #   @return [Integer]
      alias __id__ attribute

      # @return [#__id__]
      def id
        attributes[:__id__]
      end

      # @return [String, #__id__]
      def slug
        attributes[:slug] || __id__
      end

      # @return [String]
      def highlight
        attributes[:__highlight__]
      end

      # @return [.model]
      def model
        self.class.model
      end

      # @return [.model_name]
      def model_name
        self.class.model_name
      end

      # @return [ActiveRecord::Base] The represented {#model} matching {#id}
      def to_model
        model.find(id)
      end

      # @param [Base] other
      #
      # @return [-1] if {#rank} < `other.rank`
      # @return [0] if {#rank} == `other.rank`
      # @return [1] if {#rank} > `other.rank`
      def <=>(other)
        rank <=> other.rank
      end

      # @note ActiveModel compatibility
      def persisted?
        true
      end

      def to_partial_path
        model._to_partial_path
      end

      # @param [Symbol,] args A list of {#attribute_names}
      #
      # @return [Hash] A new Hash including the given attributes
      def slice(*args)
        args.each_with_object({}) { |node, h| (value = send(node)) && h[node] = value }
      end

      # @param [Symbol,] args A list of {#attribute_names}
      #
      # @return [Hash] A new Array including the value of the given attributes
      def values_at(*args)
        args.each_with_object([]) { |node, arr| (value = send(node)) && arr << value }
      end

      private

        def method_missing(method, *)
          attributes.fetch(method) { super }
        end

        def respond_to_missing?(method, *)
          attributes.key?(method) || super
        end
    end
  end

  module ClassMethods
    # @!attribute [rw] model
    #   @return [ActiveRecord::Base]
    attr_accessor :model

    # @return [ActiveModel::Name]
    def model_name
      model.model_name
    end
  end
end
