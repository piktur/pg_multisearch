# frozen_string_literal: true

module PgMultisearch
  module Index::Relation::Pagination
    # @!attribute [r] count
    #   @return [Integer]
    attr_accessor :count

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

    alias length count
    alias size length
  end
end
