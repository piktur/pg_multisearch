# frozen_string_literal: true

module PgMultisearch
  module Index
    class Meta
      class Projections < ::Hash
        def initialize
          super

          %i(
            content
            dmetaphone
            searchable_id
            searchable_type
            trigram
          ).each do |id|
            self[id] = projection(id)
          end

          self[:highlight] = Relation::WithHighlight::HIGHLIGHT_ALIAS
          self[:rank]      = Relation::Rank::RANK_ALIAS
          self[:tsearch]   = self[:content]
        end

        %i(
          content
          data
          date
          dmetaphone
          highlight
          rank
          searchable_id
          searchable_type
          trigram
          tsearch
        ).each do |id|
          # @return [ast.SqlLiteral]
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def id
              self[:#{id}]
            end
          RUBY
        end

        def []=(key, value)
          super(key, projection(value))
        end

        private

          def projection(projection)
            Adapters.ast.sql(projection.to_s.freeze).freeze
          end
      end

      # @!attribute [r] weights
      #   @return [Array<'A', 'B', 'C', 'D'>]
      attr_reader :weights

      def initialize
        @projections = Projections.new
        @weights     = %w(A B C D).map(&:freeze).freeze

        yield(self) if block_given?

        freeze
      end

      # @!attribute [rw] table_name
      #   @return [String]
      def table_name
        @table_name || 'pg_multisearch_index'.freeze
      end

      def table_name=(str)
        @table_name = str.freeze
      end

      # @param [Array<Symbol>]
      #
      # @return [Hash<Symbol=>ast.SqlLiteral>]
      # @return [Array<ast.SqlLiteral>] if args
      def projections(*args)
        if args.present?
          @projections.values_at(*args.map(&:to_sym))
        else
          @projections
        end
      end

      # @param [Array<Symbol>]
      #
      # @return [Boolean]
      def projections?(*args)
        projections(*args).present?
      end

      # @param [Symbol]
      #
      # @return [Boolean]
      def projection?(projection)
        @projections[projection.to_sym].present?
      end

      # @param [Symbol]
      #
      # @raise [KeyError] if missing
      #
      # @return [ast.SqlLiteral]
      def projection(projection)
        @projections.fetch(projection)
      end

      # @param [Array<Symbol>]
      #
      # @return [Hash{Symbol=>Symbol}]
      # @return [Array<Symbol>] if args
      def strategies(*args)
        if args.present?
          _strategies.values_at(*args.map(&:to_sym)).map(&:strategy_name)
        else
          _strategies
        end
      end

      # @param [Array<Symbol>]
      #
      # @return [Boolean]
      def strategies?(*args)
        strategies(*args).present?
      end

      # @param [Symbol]
      #
      # @return [Boolean]
      def strategy?(strategy)
        _strategies[strategy].present?
      end

      # @param [Symbol]
      #
      # @raise [KeyError] if missing
      #
      # @return [Symbol]
      def strategy(strategy)
        _strategies.fetch(strategy).strategy_name
      end

      # @return [Symbol]
      def default_strategy
        ::PgMultisearch::Strategies.default
      end

      private

        def _strategies
          ::PgMultisearch::Strategies.strategies
        end

        def intialize_copy(source)
          super(source)

          @projections = source.instance_variable_get(:@projections)

          self
        end
    end
  end
end
