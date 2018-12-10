# frozen_string_literal: true

module PgMultisearch
  # @example
  #   class Search
  #     include PgMultisearch::Search
  #   end
  #
  #   params = { 'query' => 'query', 'type' => 'SearchableType }
  #   options = {}
  #
  #   search = Search.new(params, options)
  #
  #   # Extend the default scope
  #   search.results do |relation|
  #     relation
  #       .page(params[:page])
  #       .extending(::Search::Pagination)
  #   end
  #
  #   # Materialize the relation
  #   search.to_a
  module Search
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # @!attribute [rw] types
      #   @return [PgMultisearch::Types] An ordered array of searchable types
      attr_reader :types

      # @param [Array<ActiveRecord::Base>] types
      def types=(*types)
        @types = Types.new(*types.map { |t| ::Object.const_get(t, false) })
      end
    end

    # @!attribute [rw] query
    #   @return [String]
    attr_accessor :query

    # @!attribute [r] type
    #   @return [Type]
    attr_reader :type

    # @!attribute [rw] scope
    #   @return [ActiveRecord::Relation]
    attr_accessor :scope

    # @!attribute [r] options
    #   @return [Hash]
    attr_reader :options

    # @param [Hash] params The request parameters
    # @param [Hash] options The scope options
    #
    # @!option [String] params :query
    # @!option [Integer] params :type
    # @!option [Document::Rank::CRITERION] params :ranked_by
    # @!option [Boolean] options :preload Preload {Index#searchable} associations
    def initialize(params, options = ::EMPTY_HASH)
      if params
        self.query = params['query']
        self.type  = params['type']
        options[:ranked_by] = params['ranked_by'] || ':age'
      end

      @options = options
    end

    # @return [void]
    def type=(value)
      @type = value.present? ? Search.types[value.to_i] : nil
    end

    # @yieldparam [ActiveRecord::Relation] relation
    #   @see Index.search
    #
    # @return [ActiveRecord::Relation]
    def results(&block)
      self.scope = model.search(query, type: type, **options, &block)
    end

    # @return [Results] The materialized relation
    def loaded
      @loaded ||= Results.call(scope, ranked_by).results
    end
    alias to_a loaded

    # @return [Integer]
    def count
      loaded.size # avoid additional query
    end

    # @return [Enumerator]
    def each(&block)
      to_a.each(&block)
    end

    private

      def model
        ::PgMultisearch::Index
      end
  end
end
