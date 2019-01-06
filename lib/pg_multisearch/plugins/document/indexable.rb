# frozen_string_literal: true

module PgMultisearch
  module Document
    module Indexable
      class << self
        def call(record)
          { record.pg_multisearch_index.projection(:data) => record.as_document }
        end
      end

      module ClassMethods
        def pg_multisearch_rebuilder
          @pg_multisearch_rebuilder ||= Document::Index::Rebuilder.new(self)
        end
      end

      def included(base)
        base.include AsDocument
        base.extend ClassMethods

        base.pg_multisearch_options.additional_attributes << Indexable.method(:call)

        super
      end
    end
  end
end
