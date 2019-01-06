# frozen_string_literal: true

module PgMultisearch::Document
  # {AsDocument} adds conversion methods {#to_document} and {#as_document}.
  #
  # @see Document
  #
  # @example
  #   class Record
  #     def as_document
  #       super.tap do |h|
  #         h['attribute']   = attribute
  #         h['association'] = association.as_document
  #       end
  #     end
  #   end
  module AsDocument
    def self.included(base)
      base.extend ClassMethods
    end

    # :nodoc
    module ClassMethods
      # @param [Hash, String] data
      # @param [Float] rank
      # @param [String] highlight
      #
      # @return [Base]
      #   An immutable struct containing the denormalized `input`
      def to_document(data, rank = 0.0, highlight = nil)
        self::Document.new(data, rank, highlight)
      end
    end

    # @see ClassMethods#to_document
    def to_document(data = as_document, rank = 0.0)
      self.class.to_document(data, rank)
    end

    # @yieldparam [Hash{String=>Object}]
    #   Yields a Hash containing the default fields to the block
    #
    # @see Indexable#searchable_text
    #
    # @return [Hash] The denormalized document content
    def as_document
      {
        '__id__'.freeze   => id,
        '__type__'.freeze => self.class.to_s
      }.tap do |doc|
        doc['slug'.freeze] = slug if respond_to?(:slug)

        block_given? && yield(doc).each { |attr, val| doc[attr.to_s] = val }
      end
    end
  end

  ::PgMultisearch.const_set(:AsDocument, AsDocument)
end
