# frozen_string_literal: true

module PgMultisearch
  module Index::ClassMethods
    # @return [Set<Symbol>] A list of scope names
    def scopes
      @scopes ||= ::Set.new
    end

    # @return [Meta]
    def meta
      @meta ||= Index::Meta.new
    end

    # @param (see Meta#projections)
    #
    # @return [Array<ast.SqlLiteral>]
    def projections(*args)
      meta.projections(*args)
    end

    # @param [Symbol] key
    #
    # @raise [KeyError] if `key` missing
    #
    # @return [ast.SqlLiteral]
    def projection(key)
      meta.projection(key)
    end
  end
end
