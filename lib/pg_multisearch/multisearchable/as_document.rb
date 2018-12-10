# frozen_string_literal: true

module PgMultisearch::Multisearchable
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
      #
      # @return [Search::Document]
      #   An immutable struct containing the denormalized `input`
      def to_document(data, rank)
        self::Document.new(data, rank)
      end
    end

    # @see ClassMethods#to_document
    def to_document(data = as_document, rank = 0.0)
      self.class.to_document(data, rank)
    end

    # @return [Hash] The denormalized document content
    def as_document
      {
        '__id__'   => id,
        '__type__' => self.class.to_s
      }
    end
  end
end
