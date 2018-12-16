# frozen_string_literal: true

module PgMultisearch
  module Document
    module Indexable
      class << self
        def call(record)
          { Document::DATA_COLUMN => record.as_document }
        end
      end

      module ClassMethods
        def pg_multisearch_rebuilder
          @pg_multisearch_rebuilder ||= Document::Rebuilder.new(self)
        end
      end

      def included(base)
        base.pg_multisearch_options[:additional_attributes] << Indexable.method(:call)
        base.include AsDocument
        base.extend ClassMethods

        super
      end
    end
  end
end
