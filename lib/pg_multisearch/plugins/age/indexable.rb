# frozen_string_literal: true

module PgMultisearch
  module Age
    module Indexable
      class << self
        # @param [ActiveRecord::Base] record
        #
        # @return [Hash]
        def call(record)
          { (attribute = attribute(record)) => Indexable.normalize(record.send(attribute)) }
        end

        # @return [String]
        def column(record)
          record.pg_multisearch_index.projection(:date)
        end

        # @param [Integer, Date, DateTime] value
        #   A date value indicative of a searchable record's *contemporaneity*.
        #   This date will be stored with the document and is used to compare the relative age of a result.
        #
        # @return [DateTime]
        def normalize(value = 0)
          case value
          when ::DateTime, ::Time then value.utc
          when ::Integer          then ::Time.at(value)
          when ::Date             then value.to_datetime
          end
        end
      end

      def included(base)
        base.pg_multisearch_options.additional_attributes << Indexable.method(:call)

        super
      end
    end
  end
end
