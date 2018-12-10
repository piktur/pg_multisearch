# frozen_string_literal: true

module PgMultisearch
  module Compatibility
    def build_quoted(string)
      ::PgSearch::Compatibility.build_quoted(string)
    end
  end
end
