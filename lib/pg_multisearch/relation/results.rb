# frozen_string_literal: true

module PgMultisearch
  # Materializes the relation and decorates the denormalized data for each result.
  class Relation::Results
    include ::Enumerable

    # @attribute [rw] results
    #   @return [Array<Document::Base>]
    attr_reader :results

    # @attribute [r] relation
    #   @return [ActiveRecord::Relation]
    attr_reader :relation

    # @attribute [rw] ranked_by
    #   @return [Document::Rank::CRITERION]
    attr_accessor :ranked_by

    # @param [ActiveRecord::Relation] relation
    # @param [Symbol] ranked_by
    #
    # @return [Results]
    def self.call(relation, ranked_by)
      new(relation, ranked_by)
    end

    # @param [ActiveRecord::Relation] relation
    # @param [Symbol] ranked_by The ranking criteria
    def initialize(relation, ranked_by = Document::Rank.default)
      @ranked_by = ranked_by
      @relation  = relation
    end

    # @return [Enumerator]
    def each(&block)
      results.each(&block)
    end

    # @return [Array<Document::Base>]
    def results
      @results ||= relation.map { |t| result(t) }.tap do |proxy|
        proxy.extend(CollectionProxy)
        proxy.relation = relation
      end
    end

    protected

      # @return [Document::Base]
      def result(tuple)
        type(tuple.searchable_type).to_document(tuple.data, tuple.pg_search_rank)
      end

      # @return [ActiveRecord::Base]
      def type(type)
        ::Object.const_get(type, false)
      end
  end
end
