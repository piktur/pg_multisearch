# frozen_string_literal: true

module PgMultisearch
  # @example
  #   class Search
  #     include PgMultisearch::Search
  #   end
  #
  #   params  = { 'search' => 'query', 'type' => 'Organisation' }
  #   options = {
  #     preload:   true,
  #     threshold: 0.6,
  #     weights:   %w(A B)
  #   }
  #
  #   search = Search.new(options)
  #
  #   search.call(params)
  #
  #   # or
  #
  #   search.call(params, scope_name: :suggestions)
  #
  #   # or
  #
  #   search.call(params) do |current_scope, builder|
  #     current_scope
  #       .where(%{ data @> '{"name":"von"}'::jsonb })
  #       .page(page)
  #   end
  #
  #   # Materialize the relation
  #   search.to_a
  #
  #   # Run another search
  #   search.call(params, scope_name: :suggestions, limit: 10).to_a
  module Search
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # @!attribute [rw] types
      #   @return [PgMultisearch::Types] An ordered array of searchable types
      attr_reader :types

      # @example
      #   class SearchControler
      #     def index
      #       @search, @results = Search[params, :search]
      #     end
      #   end
      #
      # @param [Hash] params
      # @param [Symbol] scope_name One of {Index::ClassMethods#scopes}
      #
      # @return [Search]
      def call(params, options = {}, &block)
        new(options).tap do |search|
          # search.tap { |obj| obj.call(scope_name, options, &block) }.to_a
          search.call(params, options, &block) # Don't load the relation
        end
      end
      alias [] call

      # @yieldparam [Configuration::Scopes]
      #
      # @return [Configuration::Scopes]
      def configure(&block)
        index.configure(&block)
      end

      # @return [Configuration::Scopes]
      def config
        index.config
      end

      # @!attribute [rw] index
      #   @return [Index::Base]
      attr_writer :index

      # @return [Index::Base]
      def index
        @index ||= ::PgMultisearch::Index::Base
      end
      alias model index

      # @param [Array<ActiveRecord::Base>] types
      #
      # @return [void]
      def types=(types)
        @types = Types.new(*types.map do |type|
          if type.is_a?(::String) || type.is_a?(::Symbol)
            ::Object.const_get(type, false)
          else
            type
          end
        end)
      end
    end

    # @!attribute [rw] input
    #   @return [String]
    attr_accessor :input
    alias query input

    # @!attribute [r] type
    #   @return [Type]
    attr_reader :type

    # @!attribute [r] options
    #   @return [Hash]
    attr_reader :options

    # @!attribute [rw] scope
    #   @return [ActiveRecord::Relation]
    attr_accessor :scope

    # @param [Hash] options The scope options
    #
    # @option [String] params :search
    # @option [Hash] params :order (:desc)
    # @option [Hash] params :page
    # @option [Boolean] options :preload
    #   Preload {Index#searchable} associations
    # @option [Boolean] options :threshold
    #   Include results with a rank greater than the specified `threshold`
    # @option [Boolean] options :weights
    #   Search against the document sections having the specified weights
    def initialize(options = {})
      @options = options
    end

    # @param [Hash] params The request parameters
    # @param (see #initialize)
    #
    # @option [Symbol] options :scope_name (:search)
    #
    # @return [self]
    def call(params, scope_name: :search, **options, &block)
      @loaded = false

      self.options.update(options)

      search_params(params[:search])
      page_params(params[:page])

      send(scope_name, &block)

      self
    end

    # @yieldparam (see Index::Scopes#search)
    #
    # @return [self]
    def search(loader: Index::Relation::Loader, **, &block)
      self.scope  = index.search(input, page: page, limit: limit, **options, &block)
      self.loader = loader
      self
    end

    # The default loading mechanism simply calls `#load` on the {#scope} and returns the hydrated
    # relation. To improve performance you may implement a custom loading mechanism utilising
    # `connection.select_all` or `connection.execute` within a block.
    #
    # @yieldparam [ActiveRecord::Relation] current_scope
    #   Yields the current {#scope} to the block
    # @yieldreturn [Enumerable] The materialized relation
    #
    # @return [ActiveRecord::Relation, Array] The materialized relation
    def load(&block)
      return scope if loaded?

      self.scope = loader.call(&block).tap { loaded! }
    end
    alias to_a load

    def results
      to_a
    end

    # @return [Integer] Returns the total count of the loaded {#scope}
    def size
      loader.size
    end

    # @return [Enumerator]
    def each(&block)
      to_a.each(&block)
    end

    # @param [Integer, String, Indexable] value
    #
    # @return [void]
    def type=(value)
      options[:type] = value.present? ? self.class.types[value] : nil
    end

    # @param [:desc, :asc] value
    #
    # @return [void]
    def order=(value)
      options[:order] = /\A(desc|asc)\z/i =~ value ? $1.downcase.to_sym : :desc
    end

    def inspect
      "#<Search #{options.map { |k, v| "#{k}=#{v.inspect}" }.join(' ')}>"
    end

    private

      # @!attribute [rw] loader
      #   @return [Index::Relation::Loader]
      attr_reader :loader

      def loader=(klass)
        @loader = klass.new(scope, options)
      end

      def loaded!
        @loaded = true
      end

      def loaded?
        @loaded
      end

      # @return [Index::Base]
      def index
        self.class.index
      end
      alias model index

      # @note Convenience method exposing {Index::Base.projections} to the delegator.
      #
      # @return [Index::Meta::Projections]
      def projections
        meta.projections
      end

      # @note Convenience method exposing {Index::Base.meta} to the delegator.
      #
      # @return [Index::Meta]
      def meta
        index.meta
      end

      # @todo Handle nested page parameters
      #
      # @param [Integer, Hash] params
      #
      # @return [void]
      def page_params(params)
        options[:page] = case params
        when ::String  then params.to_i
        when ::Integer then params
        when ::Hash    then params.fetch(:page).to_i
        end
      end

      # @param [Hash] params
      #
      # @option [String] params :query
      # @option [Integer] params :type
      #
      # @return [void]
      def search_params(params)
        return if params.nil?

        self.order = params[:order]
        self.input = params[:query]
        self.type  = params[:type]
      end

      # @return [Integer]
      def page
        options[:page]
      end

      # @return [Integer]
      def limit
        options[:limit]
      end
  end
end
