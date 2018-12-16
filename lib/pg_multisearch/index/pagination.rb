# frozen_string_literal: true

module PgMultisearch
  module Index::Pagination
    # @!attribute [r] relation
    #   @return [ActiveRecord::Relation]
    attr_accessor :relation

    # @!attribute [r] page
    #   @return [Integer]
    attr_accessor :page

    # @!attribute [r] limit
    #   @return [Integer]
    attr_accessor :limit

    alias current_page page

    # @return [Integer]
    def total_pages
      (count.to_f / limit).ceil
    end

    alias limit_value limit

    # @return [Integer]
    def offset
      (page - 1) * limit
    end

    # @return [Integer]
    def count
      @count ||= execute(relation.count.to_sql).getvalue(0, 0)
    end
    alias size count

    private

      # @return [PG::Result]
      def all
        execute(relation.to_sql)
      end

      # @param [String] sql
      #
      # @return [PG::Result]
      def execute(sql)
        connection.execute(sql)
      end

      def connection
        relation.connection
      end

      def method_missing(method, *args)
        *args, include_private = args
        respond_to_missing?(method, include_private) && relation.send(method, *args) || super
      end

      def respond_to_missing?(method, include_private = false)
        relation.respond_to?(method) || super
      end
  end
end
