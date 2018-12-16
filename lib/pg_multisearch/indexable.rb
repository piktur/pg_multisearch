# frozen_string_literal: true

module PgMultisearch
  # `PgSearch#multisearchable` does not honour attribute weight. Indexable reimplements
  # `PgSearch::Multisearchable#pg_search_document_attrs` allowing indexed data to be weighted.
  module Indexable
    def self.association(&block)
      @association ||= block
    end

    def self.callbacks(&block)
      @callbacks ||= block
    end

    association do
      has_one :pg_search_document,
              as:          :searchable,
              class_name:  'PgMultisearch::Index',
              dependent:   :delete,
              foreign_key: :searchable_id,
              inverse_of:  :searchable
    end

    callbacks do
      after_save  :update_pg_search_document,
                  if: -> { ::PgSearch.multisearch_enabled? }
    end

    module ClassMethods
      attr_accessor :pg_multisearch_options

      def self.extended(base)
        base.pg_multisearch_options = {
          additional_attributes: []
        }
      end

      def indexable(options = {})
        options[:additional_attributes] =
          pg_multisearch_options[:additional_attributes] |
          Array(options[:additional_attributes])

        self.pg_multisearch_options = options
      end
      alias multisearchable indexable

      def pg_multisearch_rebuilder
        @pg_multisearch_rebuilder ||= Index::Rebuilder.new(self)
      end
    end

    def self.included(base)
      base.extend ClassMethods

      base.class_eval(&association)
      base.class_eval(&callbacks)

      super
    end

    def pg_multisearch_options
      self.class.pg_multisearch_options
    end

    def pg_multisearch_rebuilder
      self.class.pg_multisearch_rebuilder
    end

    # @example
    #   model = Class.new(ActiveRecord::Base) do
    #     include PgMultisearch::Indexable
    #
    #     indexable(
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
      pg_multisearch_options[:against].each_with_object({}) do |(attr, weight), h|
        value = send(attr)

        value = case value
        when ::ActiveRecord::Base
          value.searchable_text.values.flat_map(&:values).join(' ')
        when ::Hash
          value.values.join(' ')
        when ::Array
          value.join(' ')
        when nil
          next
        else
          value
        end

        (h[weight] ||= {})[attr] = value if value.present?
      end
    end

    # @return [Hash]
    def pg_search_document_attrs
      { Index::CONTENT_COLUMN => searchable_text }.tap do |h|
        pg_multisearch_options[:additional_attributes].each do |fn|
          fn.to_proc.call(self).each { |k, v| h[k.to_s] = v }
        end
      end
    end

    def should_update_pg_search_document?
      Array(pg_multisearch_options[:update_if])
        .all? { |fn| fn.to_proc.call(self) }
    end

    def update_pg_search_document
      positive, negative = pg_multisearch_options.values_at(:if, :unless)

      if Array(positive).all? { |fn| fn.to_proc.call(self) } &&
         Array(negative).all? { |fn| !fn.to_proc.call(self) }
        create_or_update_pg_search_document
      else
        pg_search_document.destroy if pg_search_document
      end
    end

    # @todo Execute concurrently
    # @todo Run create/update callbacks explicitly (but, who in their right mind would trigger callbacks here?)
    # @todo Use INSERT INTO pg_search_documents ON CONFLICT DO UPDATE ... if postgresql_version > 95000
    #
    # @return [void]
    def create_or_update_pg_search_document
      command = (!pg_search_document && :insert) ||
                (should_update_pg_search_document? && :update)

      return unless command

      self.class.connection.execute(
        pg_multisearch_rebuilder.call(self, command: command).to_sql
      )
    end
  end
end
