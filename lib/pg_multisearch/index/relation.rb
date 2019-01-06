# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    extend ::ActiveSupport::Autoload

    autoload :AsPreparedStatement
    autoload :AsStatement
    autoload :BindParams
    autoload :Builder
    autoload :Count
    autoload :Constructor
    autoload :Filter
    autoload :Loader
    autoload :Merge
    autoload :Pagination
    autoload :Preloader
    autoload :Projections
    autoload :Rank
    autoload :WithCount
    autoload :WithCTE
    autoload :WithHighlight
    autoload :WithLimitBind
    autoload :WithOffsetBind
    autoload :WithRank
    autoload :WithTableAlias
    autoload :Strategies

    include ::PgMultisearch.adapter

    # @return [ast.SqlLiteral]
    FILTER_TABLE_PK = ast.sql('id'.freeze).freeze
    private_constant :FILTER_TABLE_PK

    # @return [ast.SqlLiteral]
    FILTER_TABLE_PK_ALIAS = ast.sql('pg_multisearch_id'.freeze).freeze

    # @param (see Constructor#initialize)
    def self.[](config)
      Constructor[config]
    end

    # @!attribute [r] config
    #   @return [Configuration]
    attr_reader :config

    # @!attribute [r] index
    #   @return [Index::Base]
    attr_reader :index
    alias model index

    # @!attribute [rw] scope
    #   @return [ActiveRecord::Relation]
    attr_accessor :scope

    # @!attribute [rw] select_manager
    #   @return [ast.SelectManager]
    attr_accessor :select_manager
    alias arel select_manager

    # @!attribute [r] input
    #   @return [String]
    attr_accessor :input

    # @!attribute [r] filter
    #   @return [Filter]
    attr_reader :filter

    # @!attribute [r] filter_strategies
    #   @return [Array<Symbol>]
    attr_reader :filter_strategies

    # @!attribute [r] with_values
    #   @return [Array<ast.Node>]
    attr_accessor :with_values

    # @!attribute [r] projections
    #   @return [Projections]
    attr_reader :projections

    # @!attribute [r] sources
    #   @return [Array<ast.Node>]
    attr_reader :sources

    # @!attribute [r] constraints
    #   @return [Array<ast.Node>]
    attr_reader :constraints

    # @!attribute [r] orders
    #   @return [Array<ast.Node>]
    attr_reader :orders

    # @!attribute [r] limit
    #   @return [Integer, nil]
    attr_accessor :limit

    # @!attribute [r] offset
    #   @return [Integer, nil]
    attr_accessor :offset

    # @!attribute [r] references
    #   @return [Array<ast.SqlLiteral>]
    attr_accessor :references

    # @param [Configuration::Base] config
    # @param [Array<Strategies::Strategy>] filter_by
    def initialize(config, filter_by) # rubocop:disable MethodLength
      @config = config
      @index  = config.index

      @with_values  = []
      @projections  = []
      @sources      = []
      @constraints  = []
      @orders       = []
      @limit        = nil
      @offset       = nil
      @references   = []

      @filter_strategies = filter_by
    end

    # @param [ActiveRecord::Relation] current_scope
    # @param [Hash] options
    #
    # @option [String] options :input
    # @option [String] options :type
    # @option [Integer] options :limit
    # @option [Integer] options :page
    #
    # @return [Array<ast.SelectManager, BindParams>]
    def call(current_scope, **options)
      self.scope  = current_scope
      self.input  = options[:input]
      self.filter = self

      apply(options)

      yield(self) if block_given?

      # @todo Should be either/or not both
      # self.select_manager = Merge[self, scope.arel, adapter: :arel, **options]
      self.scope = Merge[self, scope, adapter: :active_record, **options]

      self
    end

    # {#apply} seeks to reuse cached query fragments when possible. Fragments likely to change
    # WILL BE replaced.
    #
    # @note Extensions SHOULD use {#apply} to transform the relation
    #
    # @example
    #   module WithFeature
    #     def apply(**options)
    #       super do
    #         yield(self) if block_given?
    #
    #         # apply the feature
    #       end
    #     end
    #   end
    #
    #   Relation.new(*args).extend(WithFeature)
    def apply(limit: nil, page: nil, **options) # rubocop:disable AbcSize, MethodLength
      filter_cte.call(options)

      self.filter_cte_expression = filter_cte.expression
      self.query_cte_expression = query_cte.expression

      with_values.replace([query_cte_alias, filter_cte_alias] | with_values)
      sources.replace([query_cte_table, filter_cte_table] | sources)
      references.replace(filter.references | references)

      bind_params.merge(filter.bind_params) if filter.bind_params.present?

      yield if block_given?

      if    page  then paginate(limit, page)
      elsif limit then take(limit)
      end
    end

    def ranked?
      false
    end

    # @param [Class] other
    #
    # @return [Boolean]
    def ranked_with?(other)
      ranked? && rank.is_a?(other)
    end

    # @return [Count]
    def count
      @count ||= Count.new(self)
    end

    # @return [ast.Table]
    def table
      @table ||= ast.table(index.table_name, index) # index.arel_table
    end

    # @param [self] relation
    def filter=(relation)
      @filter = Filter::Base.allocate.tap do |obj|
        if prepared_statement?
          obj.extend(AsPreparedStatement)
          obj.bind_params.offset = bind_params.count
        else
          obj.extend(AsStatement)
        end

        obj.send(:initialize, relation, relation.filter_strategies)
      end
    end

    alias filter_cte filter

    # @return [ast.Table]
    def filter_cte_table
      filter_cte.table
    end

    # @!attribute [rw] filter_cte_expression
    #   @return [ast.Node]
    attr_accessor :filter_cte_expression
    # def filter_cte_expression
    #   filter_cte.expression
    # end

    # @return [ast.Node]
    def filter_cte_alias
      ast.nodes.as(
        filter_cte_table_alias,
        ast.nodes.group(filter_cte_expression)
      )
    end

    # @return [ast.Node]
    def filter_cte_table_alias
      filter_cte.table_alias
    end

    # @return [Array<ast.Node>]
    def filter_cte_projections
      filter_cte_expression.projections
    end

    # @return [Query]
    def query_cte
      filter.query
    end

    # @return [ast.Table]
    def query_cte_table
      query_cte.table
    end

    # @!attribute [rw] query_cte_expression
    #   @return [ast.Node]
    attr_accessor :query_cte_expression

    # @return [ast.Node]
    def query_cte_alias
      ast.nodes.as(
        query_cte_table_alias,
        ast.nodes.group(query_cte_expression)
      )
    end

    # @return [ast.Node]
    def query_cte_table_alias
      query_cte.table_alias
    end

    # @return [ast.Node]
    def join
      project_append(
        FILTER_TABLE_PK
      )

      ast.nodes.inner_join(
        ast.as(filter_cte_expression, filter_cte_table_alias),
        ast.nodes.on(pk.eq(fk))
      )
    end

    # @param [Array<Symbol, String>] projections
    #
    # @return [void] Append the given projections to {#projections} and {#filter_cte_expression}
    def project_append(*other)
      _project_append(projections, other, filter_cte_table)
      _project_append(filter_cte_projections, other, table)
    end
    alias select_append project_append

    # @return [Array<ast.Node>]
    def order(*args)
      orders.replace(orders | args)
    end

    # @param [Array<ast.Node, ast.Node>]
    def order_prepend(*args)
      project_append(*args.map(&:expr))
      orders.replace(args | orders)
    end

    # @param [Integer] limit
    #
    # @return [void]
    def take(limit)
      @limit = connection.sanitize_limit(limit) # bind(:limit, connection.sanitize_limit(limit))
    end

    # @param [Integer] offset
    #
    # @return [void]
    def skip(offset)
      @offset = offset # bind(:offset, offset)
    end

    # @param [Integer] limit
    # @param [Integer] page
    #
    # @return [void] Apply LIMIT and OFFSET to outer SELECT
    def paginate(limit, page)
      take(limit)
      skip(page ? (page - 1) * limit : 0)
    end

    def inspect
      # :0x#{'%x' % (__id__ << 1)
      "#<#{self.class} filter=#{filter.inspect}#{" rank=#{rank.inspect}" if ranked?}>"
    end

    protected

      # @return [ActiveRecord::Base]
      def connection
        index.connection
      end

      # @param [Array<ast.Attribute, ast.Node>] left
      # @param [Array<ast.Attribute, ast.Node>] right
      # @param [ast.Table] source
      #
      # @return [void]
      def _project_append(left, right, source)
        right = right.each_with_object([]) do |e, a|
          case e
          when ast.Node, ast.Attribute            then a << e
          when ast.SqlLiteral, ::String, ::Symbol then a << source[e.to_s]
          end
        end

        left.replace(left | right)
      end

      # @return [ast.Node]
      def fk
        filter_cte_table[:id]
      end

      # @return [ast.Node]
      def pk
        table[:id]
      end
  end
end
