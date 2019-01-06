# frozen_string_literal: true

require 'digest'

module PgMultisearch
  class Index::Relation
    module WithTableAlias
      # @note PostgreSQL limits names to 32 characters
      #
      # @return [String]
      def self.alias(*elements)
        name = Array(elements).compact.join('_')
        "pg_multisearch_#{::Digest::SHA2.hexdigest(name)}"[0, 32]
      end

      def pg_multisearch_table_alias(include_counter = false)
        elements = [table_name]

        if include_counter
          count = pg_multisearch_scope_count_increment
          count > 0 && elements << count
        end

        WithTableAlias.alias(elements)
      end

      private

        attr_writer :pg_multisearch_scope_count

        def pg_multisearch_scope_count
          @pg_multisearch_scope_count ||= 0
        end

        def pg_multisearch_scope_count_increment
          self.pg_multisearch_scope_count = (count = pg_multisearch_scope_count) + 1
          count
        end
    end
  end
end
