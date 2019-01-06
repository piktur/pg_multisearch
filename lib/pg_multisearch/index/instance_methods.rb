# frozen_string_literal: true

module PgMultisearch
  module Index::InstanceMethods
    # @return [Meta]
    def meta
      self.class.meta
    end

    # @return [Float]
    def pg_multisearch_rank
      self[projection(:rank)]
    end
    alias rank pg_multisearch_rank

    # @return [String]
    def pg_multisearch_highlight
      self[projection(:highlight)]
    end
    alias highlight pg_multisearch_highlight
  end
end
