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

    association do |index, **options|
      options[:as]          ||= :searchable
      options[:inverse_of]  ||= :searchable
      options[:foreign_key] ||= :searchable_id

      has_one :pg_multisearch_document,
              class_name: index.name,
              dependent:  :delete,
              **options
    end

    callbacks do
      after_save  :update_pg_multisearch_document,
                  if: -> { ::PgMultisearch.enabled? }
    end

    def self.included(base)
      base.extend ClassMethods

      super
    end

    module ClassMethods
      attr_accessor :pg_multisearch_options

      def self.extended(base)
        base.pg_multisearch_options = Configuration::Indexable.new
      end

      # @param [String] index The class name of the {Index::Base} to use.
      #
      # @return [Configuration::Indexable]
      def indexable(index = '::PgMultisearch::Index::Base'.freeze)
        pg_multisearch_options.tap do |obj|
          obj.index = index

          class_exec(obj.index, &Indexable.association)
          class_eval(&Indexable.callbacks)

          yield(obj, obj.index) if block_given?

          obj.finalize!
        end
      end
      alias multisearchable indexable

      # @return [Rebuilder]
      def pg_multisearch_rebuilder
        @pg_multisearch_rebuilder ||= Rebuilder.new(self)
      end

      # @return [Index::Base]
      def pg_multisearch_index
        pg_multisearch_options.index
      end
    end

    def pg_multisearch_options
      self.class.pg_multisearch_options
    end

    def pg_multisearch_rebuilder
      self.class.pg_multisearch_rebuilder
    end

    def pg_multisearch_index
      self.class.pg_multisearch_index
    end

    # @example
    #   model = Class.new(ActiveRecord::Base) do
    #     include PgMultisearch::Indexable
    #
    #     indexable(Index::Base) do |config|
    #       config.add('A', :uppermost)
    #       config.add('B', :upper) { |record| record.attribute }
    #       config.add('C', :lower)
    #       config.add('D', :lowest)
    #       config.additional_attribute { |record| { date: record.updated_at } }
    #       config.include_if { |record| record.indexable? }
    #       config.exclude_if { |record| record.indexable? }
    #       config.update_if { |record| record.updatable? }
    #       config.preloadable << :assoc
    #       config.preloadable = [assoc: [:assoc, assoc: :assoc]]
    #     end
    #   end
    #   obj = model.new(uppermost: 'A Title', upper: 'keywords, outline')
    #   obj.searchable_text # => { 'A' => 'title', 'B' => 'keywords, outline' }
    #
    # @return [Hash] Searchable attributes grouped by weight
    def searchable_text
      space = ' '.freeze

      pg_multisearch_options.against.each_with_object({}) do |(weight, attributes), h|
        next if attributes.empty?

        h = (h[weight] = {})

        attributes.each do |attr, value|
          value = case value
          when ::Symbol
            send(value)
          when ::Proc
            value.call(self)
          end

          value = case value
          when ::ActiveRecord::Base
            value.searchable_text.values.flat_map(&:values).join(space)
          when ::Hash
            value.values.join(space)
          when ::Array
            value.join(space)
          when nil, EMPTY_STRING
            next
          else
            value
          end

          h[attr] = value
        end
      end
    end

    # @return [Hash]
    def pg_multisearch_document_attrs
      { pg_multisearch_index.projection(:content) => searchable_text }.tap do |h|
        pg_multisearch_options[:additional_attributes].each do |fn|
          fn.to_proc.call(self).each { |k, v| h[k.to_s] = v }
        end
      end
    end

    # @return [Boolean]
    def should_update_pg_multisearch_document?
      # return false if pg_multisearsch_document.destroyed?

      Array(pg_multisearch_options.update_if).all? { |fn| fn.to_proc.call(self) }
    end

    # @return [void]
    def update_pg_multisearch_document
      if Array(pg_multisearch_options.include_if).all? { |fn| fn.to_proc.call(self) } &&
         Array(pg_multisearch_options.exclude_if).all? { |fn| !fn.to_proc.call(self) }
        create_or_update_pg_multisearch_document
      elsif pg_multisearch_document
        pg_multisearch_document.destroy
      end
    end

    # @todo Execute concurrently
    # @todo Run create/update callbacks explicitly (but, who in their right mind would trigger callbacks here?)
    # @todo Use INSERT INTO pg_multisearch_documents ON CONFLICT DO UPDATE ... if postgresql_version > 95_000
    #
    # @return [void]
    def create_or_update_pg_multisearch_document
      command = (!pg_multisearch_document && :insert) ||
                (should_update_pg_multisearch_document? && :update)

      return unless command

      self.class.connection.execute(
        pg_multisearch_rebuilder.call(self, command: command).to_sql
      )
    end
  end
end
