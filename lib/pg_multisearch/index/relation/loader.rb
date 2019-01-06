# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    # Loads the result set for the given relation.
    class Loader
      include ::Enumerable

      # @!attribute [r] collection
      #   @return [ActiveRecord::Relation<Indexable>] The materialized relation
      attr_reader :collection
      alias to_a collection

      # @param [ActiveRecord::Relation] current_scope
      # @param [Hash] options
      #
      # @option [Boolean] options :preload
      # @option [Integer] options :page
      # @option [Integer] options :limit
      def initialize(current_scope, **options)
        @scope   = current_scope
        @index   = scope.klass
        @options = options
      end

      def call(&block)
        @collection = load(&block)

        # @todo Mimic ActiveRecord::Relation#exec_queries
        preload if preload?

        @collection
      end

      # @return [ActiveRecord::Result]
      def load
        return yield(scope) if block_given?

        none? ? scope : scope.load
      end

      # @return [Enumerator]
      def each(&block)
        to_a.each(&block)
      end

      # @todo {Index::Relation::Count}
      #
      # @return [Integer]
      def count
        return 0 if none?

        # @todo only execute the count query if the relation is paginated, otherwise call scope.size
        return scope.size unless page # prevent additional query if non-paginated scope loaded

        arel, bind_params = count_query

        if prepared_statement?
          # connection.exec_query(arel.to_sql, index, bind_params)[0]['count'].to_i
          connection.select_value(arel.to_sql, index, bind_params).to_i
        else
          connection.execute(arel.to_sql).instance_eval do
            i = getvalue(0, 0).to_i
            # @note Ensure you call `#clear` when finished with the `PG::Result`
            #
            # @see https://deveiate.org/code/pg/PG/Result.html
            clear
            i
          end
        end
      end

      # @return [Integer]
      def size
        @size ||= count
      end
      alias length size

      # @todo Query fragments should be bound to the scope and applied JIT. They may exist as
      #   curried Procs ie. `method(:call).curry(arity == -1 ? args.length + 1 : arity + 1)`
      #   until it comes to loading the scope at which time we may choose to
      #   apply filter(s) and rank(s).
      #
      # @return [Arel::SelectManager]
      def count_query
        return @count_query if defined?(@count_query)

        # @todo I shudder to think
        bind_params = self.bind_params.dup
        arel = ::Arel::Nodes::SelectCore.new.tap do |obj|
          expression = self.arel.clone

          n = 0
          self.limit, self.offset = [*expression.limit, *expression.offset].map do |value|
            i = case value
            when /(\d+)/   then $1.to_i
            when ::Integer then value
            end

            bind_params.delete_at(i - (n += 1))[1]
          end

          expression
            .take(nil)
            .skip(nil)
            .tap { |obj| obj.orders.replace(EMPTY_ARRAY) }

          obj.projections << ::Arel.star.count(false)
          obj.froms = [expression.as(::Arel.sql('x'))]
        end

        @count_query = [arel, bind_params]
      end

      # @return [#collection]
      def preload
        # scope.preload(:searchable)

        Preloader.call(collection)
      end

      protected

        # @!attribute [r] index
        #   @return [Index::Base]
        attr_reader :index

        # @attribute [r] scope
        #   @return [ActiveRecord::Relation]
        attr_reader :scope

        # @attribute [r] options
        #   @return [Hash]
        attr_reader :options

        # @return [ast.SelectManager]
        def arel
          @arel ||= scope.arel
        end

        # @return [Array, BindParams]
        def bind_params
          @bind_params ||= scope.bind_values
        end

        # @return [Indexable]
        def type(type)
          ::Object.const_get(type, false)
        end

        # @return [Boolean]
        def prepared_statement?
          bind_params.present?
        end

        # @return [Boolean]
        def none?
          scope.is_a?(::ActiveRecord::NullRelation)
        end

        # @return [Boolean]
        def preload?
          options[:preload]
        end

        # @!attribute [rw] limit
        # @!attribute [rw] offset
        # @return [Integer]
        attr_accessor :limit, :offset

        # @return [Integer, nil]
        def page
          options[:page]
        end

        # @return [Integer, nil]
        def limit
          @limit || options[:limit]
        end

      private

        # @return [ActiveRecord::ConnectionAdapters::PostgreSQLAdapter]
        def connection
          index.connection
        end

        # def method_missing(method, *args)
        #   *args, include_private = args
        #   respond_to_missing?(method, include_private) && scope.send(method, *args) || super
        # end

        # def respond_to_missing?(method, include_private = false)
        #   scope.respond_to?(method) || super
        # end
    end
  end
end
