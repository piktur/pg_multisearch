# frozen_string_literal: true

module PgMultisearch
  class Document::Index::Rebuilder < Index::Rebuilder
    private

      def prepare(*)
        super { |values| prepare_data(values) }
      end

      def prepare_data(values)
        values[column = index.projection(:data)] = cast_to_json(values[column])
      end
  end
end
