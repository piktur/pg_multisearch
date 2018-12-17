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
      def types=(types)
        @types = Types.new(*types.map { |type|
          type.is_a?(::String) || type.is_a?(::Symbol) ? ::Object.const_get(type, false) : type
        })
      end
    end

    # @!attribute [rw] query
    #   @return [String]
    attr_accessor :query

    # @!attribute [r] type
    #   @return [Type]
    attr_reader :type

    # @!attribute [r] page
    #   @return [Integer]
    attr_reader :page

    # @!attribute [rw] scope
    #   @return [ActiveRecord::Relation]
    attr_accessor :scope

    # @!attribute [r] options
    #   @return [Hash]
    attr_reader :options

    # @param [Hash] params The request parameters
    # @param [Hash] options The scope options
    #
    # @option [String] params :search
    # @option [Hash] params :page
    # @option [Boolean] options :preload Preload {Index#searchable} associations
    # @option [Boolean] options :document Load denormalized {Document::Base}
    def initialize(params, options = {})
      @options = options
      @loaded  = false

      search_params(params[:search])
      page_params(params[:page])
    end

    # @return [void]
    def type=(value)
      @type = value.present? ? self.class.types[value.to_i] : nil
    end

    # @yieldparam (see Index.search)
    #
    # @return [ActiveRecord::Relation]
    def results(&block)
      self.scope = model.search(query, type: type, **options, &block)
    end

    # @return [ActiveRecord::Relation, Array] The materialized relation
    def load
      return scope if @loaded
      # return model.none if scope.respond_to?(:none?) && scope.none?

      self.scope = scope.none? ? scope.to_a : scope.load(*page ? [page, limit] : nil).tap { loaded! }
    end
    alias to_a load

    # @return [Integer]
    def count
      scope.size # avoid additional query
    end

    # @return [Enumerator]
    def each(&block)
      to_a.each(&block)
    end

    private

      def loaded!
        @loaded = true
      end

      # @return [ActiveRecord::Base]
      def model
        ::PgMultisearch::Index
      end

      # @return [String]
      def table_name
        model.table_name
      end

      # @todo Handle nested page parameters
      #
      # @param [Integer, Hash] params
      #
      # @return [void]
      def page_params(params)
        @page = case params
        when ::String  then params.to_i
        when ::Integer then params
        when ::Hash    then params
        end
      end

      # @param [Hash] params
      #
      # @option [String] params :query
      # @option [Integer] params :type
      # @option [String] params :ranked_by
      #
      # @return [void]
      def search_params(params)
        return if params.nil?

        self.query = params[:query]
        self.type  = params[:type]

        options[:ranked_by] = params[:ranked_by]
      end
  end
end
