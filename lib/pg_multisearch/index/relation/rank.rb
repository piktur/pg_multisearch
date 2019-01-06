# frozen_string_literal: true

module PgMultisearch
  module Index::Relation::Rank
    extend ::ActiveSupport::Autoload

    autoload :Base
    autoload :Polymorphic
    autoload :Threshold

    include ::PgMultisearch.adapter

    # @return [ast.SqlLiteral]
    RANK_COLUMN = ast.sql('rank'.freeze).freeze
    private_constant :RANK_COLUMN

    # @return [ast.SqlLiteral]
    RANK_ALIAS = ast.sql('pg_multisearch_rank'.freeze).freeze
  end
end
