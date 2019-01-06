# frozen_string_literal: true

module PgMultisearch
  module Document::Index
    module Scopes
      # @param (see Index::Scopes#search)
      #
      # @return [ActiveRecord::Relation]
      def search(input, **options, &block)
        options[:builder] = Relation::Builder

        super(input, options, &block)
      end
    end
  end
end
