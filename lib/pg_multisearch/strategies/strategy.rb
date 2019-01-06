# frozen_string_literal: true

module PgMultisearch
  module Strategies
    class Strategy
      include ::PgMultisearch.adapter

      CONCAT = ast.sql('||'.freeze).freeze
      SPACE = ast.sql(' '.freeze).freeze
      QUOTED_SPACE = ast.sql("' '".freeze).freeze

      # @!attribute [rw] input
      #   @return [String]
      attr_accessor :input

      # @!attribute [rw] table
      #   @return [ast.Table]
      attr_writer :table

      # @return [ast.Table]
      def table
        @table ||= ast.table(index.table_name, index) # index.arel_table
      end
      alias filter_cte_table table

      # @!attribute [w] query_cte_table
      #   @return [ast.Table]
      attr_accessor :query_cte_table

      # @!attribute [rw] prepared_statement
      #   @return [Boolean]
      attr_accessor :prepared_statement
      alias prepared_statement? prepared_statement

      # @!attribute [rw] bind_params
      #   @return [BindParams]
      attr_accessor :bind_params

      # @!attribute [r]
      #   @return [Configuration::Base]
      attr_reader :config
      protected :config

      # @!attribute [r]
      #   @return [Array<Symbol>]
      attr_reader :all_columns
      protected :all_columns

      # @!attribute [r]
      #   @return [Index::Base]
      attr_reader :index
      protected :index

      # @!attribute [r]
      #   @return [Normalizer]
      attr_reader :normalizer
      protected :normalizer

      # @param [Array<ast.SqlLiteral>] all_columns
      # @param [Index::Base] index
      # @param [Normalizer] normalizer
      # @param [Configuration::Base] config
      def initialize(all_columns, index, normalizer, **config)
        @all_columns = all_columns
        @index       = index
        @normalizer  = normalizer
        @config      = config
      end

      # @return [Array<Array<String, String>>] A list of projected columns and aliases
      def projections
        columns.map(&:to_s)
      end

      # @return [Boolean]
      def rank_only?
        config[:rank_only]
      end

      # @return [Symbol]
      def strategy_name
        self.class.strategy_name
      end

      private

        # @param [Object] value
        # @param [Symbol] id
        #
        # @return [ast.BindParam] if {#prepared_statement?}
        def bind(value, id = strategy_name)
          prepared_statement? ? bind_params.add(id, value) : value
        end

        # @return [ast.Node]
        def document
          columns.reduce do |left, right|
            infix(" #{CONCAT} #{QUOTED_SPACE} #{CONCAT} ".freeze, left, right)
          end
        end

        # @return [ast.Attribute] An identifier for the CTE containing the normalized query
        def query_cte_column
          return unless query_cte_table

          @query_cte_column ||= query_cte_table[strategy_name]
        end

        # @raise [ConfigurationError] if columns empty
        #
        # @return [Array<Symbol>]
        def columns
          if config[:only]
            columns = Array(config[:only])
            all_columns.select { |column| columns.include?(column) }
          else
            all_columns
          end
        end

        # @return [String]
        def dictionary
          ast.build_quoted(config[:dictionary])
        end

        # @param [ast.Node]
        #
        # @return [ast.Node]
        def normalize(expression)
          normalizer.add_normalization(expression)
        end

        # @return [ActiveRecord::ConnectionAdapters::PostgreSQLAdapter]
        def connection
          index.connection
        end

        # @return [String]
        def quoted_table_name
          connection.quote_table_name(table.table_name)
        end

        # @param [String] column
        #
        # @return [String]
        def quote_column_name(column)
          connection.quote_column_name(column)
        end

        # @return [Integer]
        def postgresql_version
          ::PgMultisearch.postgresql_version
        end

        # @param (see PgMultisearch.check!)
        def check!(*args)
          ::PgMultisearch.check!(*args)
        end
    end
  end
end
