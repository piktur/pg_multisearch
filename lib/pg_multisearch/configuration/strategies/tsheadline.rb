# frozen_string_literal: true

module PgMultisearch
  module Configuration
    module Strategies
      Tsheadline = ::Struct.new(
        *HIGHLIGHT_OPTIONS,
        :dictionary,
        :fields,
        :document
      ) do
        include Base

        FRAGMENT_DELIMITER = '&hellip;'.freeze

        defaults do |obj|
          obj.dictionary         = DICTIONARY_ENGLISH
          obj.fragment_delimiter = FRAGMENT_DELIMITER
          obj.fields             = %w(ts_headline)
        end

        def highlight_all=(bool)
          self[:highlight_all] = ast.sql(bool ? 'TRUE'.freeze : 'FALSE'.freeze).freeze
        end

        def fragment_delimiter=(str)
          self[:fragment_delimiter] = (
            str.start_with?(q = '"'.freeze) &&
            str.end_with?(q) &&
            str
          ) || "\"#{str}\""
        end

        def min_words=(int)
          self[:min_words] = int.to_i
        end

        def max_words=(int)
          self[:max_words] = int.to_i
        end

        def max_fragments=(int)
          self[:max_fragments] = int.to_i
        end

        def short_words=(int)
          self[:short_words] = int.to_i
        end

        def start_sel=(str)
          self[:start_sel] = str.to_s
        end

        def stop_sel=(str)
          self[:stop_sel] = str.to_s
        end

        # @yieldparam (see PgMultisearch::Strategies::Tsheadline#ts_headline)
        def document(fn = nil, &block)
          fetch_or_store(:document) { fn || block }
        end

        # @todo Replace explicit reference to connection
        def fields=(arr)
          arr = arr.reduce([]) do |a, e|
            case e
            when ::String then a << connection.quote(e)
            when ::Array  then a << connection.quote(e.join(','.freeze))
            end
          end

          # Apply explcit cast to text[] in case empty;
          # prevents `PG::IndeterminateDatatype: cannot determine type of empty array`.
          self[:fields] = ast.sql(
            "ARRAY[#{arr.join(',')}]::text[]".tr("\s".freeze, EMPTY_STRING)
          )
        end

        private

          # @todo Replace explicit reference to connection
          def connection
            ::ActiveRecord::Base.connection
          end
      end
    end
  end
end
