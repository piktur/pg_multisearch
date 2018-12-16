# frozen_string_literal: true

module PgMultisearch
  module Document
    class Rebuilder < Index::Rebuilder
      private

        def prepare(*)
          super { |values| prepare_data(values) }
        end

        def prepare_data(values)
          column = Document::DATA_COLUMN
          values[column] = cast_to_json(values[column])
        end
    end
  end
end
