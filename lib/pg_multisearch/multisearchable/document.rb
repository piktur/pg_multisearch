# frozen_string_literal: true

module PgMultisearch
  module Multisearchable
    module Document
      # @param [Integer, Date, DateTime] value
      #   A date value indicative of a searchable record's *contemporaneity*.
      #   This date will be stored with the document and is used to compare the relative age of a result.
      #
      # @return [DateTime]
      def self.provenance(value = 0)
        case value
        when ::DateTime, ::Time then value.utc
        when ::Integer          then ::Time.at(value)
        when ::Date             then value.to_datetime
        end
      end

      # @example
      #   model = Class.new(ActiveRecord::Base) do
      #     multisearchable(
      #       against: {
      #         uppermost: 'A',
      #         upper:     'B',
      #         lower:     'C',
      #         lowest:    'D'
      #       }
      #     )
      #   end
      #   obj = model.new(uppermost: 'A Title', upper: 'keywords, outline')
      #   obj.searchable_text # => { 'A' => 'title', 'B' => 'keywords, outline' }
      #
      # @return [Hash] Searchable attributes grouped by weight
      def searchable_text
        pg_search_multisearchable_options[:against].each_with_object({}) do |(attr, weight), h|
          value = send(attr)

          value = case value
          when ::ActiveRecord::Base
            value.searchable_text.values.flat_map(&:values).join(' ')
          when ::Hash
            value.values.join(' ')
          when ::Array
            value.join(' ')
          else
            value
          end

          # (h[weight] ||= '') << ' ' << value if value.present?
          (h[weight] ||= {})[attr] = value if value.present?
        end
      end

      # @return [Hash]
      def pg_search_document_attrs
        {
          'content' => searchable_text.to_json,
          'data' => as_document.to_json,
          'provenance' => Document.provenance(provenance)
        }.tap do |h|
          if (fn = pg_search_multisearchable_options[:additional_attributes])
            fn.to_proc.call(self).each { |k, v| h[k.to_s] = v }
          end
        end
      end
    end
  end
end
