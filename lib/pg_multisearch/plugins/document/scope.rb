# frozen_string_literal: true

module PgMultisearch
  module Document
    module Scope
      def search(query, **options, &block)
        options[:builder] = Document::Builder
        super(query, options, &block)
      end
    end
  end
end
