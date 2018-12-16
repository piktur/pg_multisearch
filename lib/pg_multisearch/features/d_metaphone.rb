# frozen_string_literal: true

module PgMultisearch
  module Features
    class DMetaphone < TSearch
      private
        def to_tsquery(input)
          dmetaphone_to_tsquery(
            string_to_dmetaphone(
              ::Arel.sql(normalize(connection.quote(input)))
            )
          ).to_sql
        end

        def to_tsvector(column)
          dmetaphone_to_tsvector(
            string_to_dmetaphone(
              ::Arel.sql(normalize(column.to_sql))
            )
          )
        end

        def tsvector
          terms = if tsvector_column
            ::Array.wrap(tsvector_column).map do |column|
              "#{quoted_table_name}.#{connection.quote_column_name(column)}"
            end
          else
            columns_to_use.map { |column| to_tsvector(column).to_sql }
          end

          ::Arel.sql(terms.join(' || '))
        end

        def string_to_dmetaphone(str)
          fn('string_to_dmetaphone', [str])
        end

        def dmetaphone_to_tsquery(str)
          fn('dmetaphone_to_tsquery', [str, *dictionary])
        end

        def dmetaphone_to_tsvector(str)
          fn('dmetaphone_to_tsvector', [str, *dictionary])
        end
    end
  end
end
