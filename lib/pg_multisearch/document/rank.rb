# frozen_string_literal: true

module PgMultisearch::Document
  Rank = Struct.new(:age, :relevance) do
    include Comparable

    CRITERION = %i(age relevance).freeze

    def self.default
      CRITERION[0]
    end

    def <=>(other)
      rank <=> other.rank
    end
  end
end
