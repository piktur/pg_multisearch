# frozen_string_literal: true

module PgMultisearch
  module Features
    class TsHeadline < Feature
      UNSUPPORTED_MSG = <<-MESSAGE.strip
        Sorry, {:using => {:tsearch => {:highlight => true}}} only works in PostgreSQL 9.0 and above.
      MESSAGE

      def initialize(model, options)
        @model = model
        @options = options[:headline]
      end

      def call(document, tsquery)
        ts_headline(document, tsquery)
      end

      def check!
        raise ::PgSearch::NotSupportedForPostgresqlVersion.new(UNSUPPORTED_MSG) if
          options && postgresql_version < 90000
      end

      private

        # @return [Arel::Nodes::Node]
        def ts_headline(document, tsquery)
          ::Arel::Nodes::NamedFunction.new(
            'ts_headline',
            [
              document,
              tsquery,
              build_quoted(options)
            ]
          )
        end

        # @see https://www.postgresql.org/docs/9.5/textsearch-controls.html 12.3.4. Highlighting Results
        #
        # @return [String]
        def options
          return unless @options.is_a?(::Hash)

          arr = []

          {
            'StartSel'     => @options[:start_sel],
            'StopSel'      => @options[:stop_sel],
            'MaxFragments' => @options[:max_fragments]
          }.each { |k, v| arr << "#{k}=#{v}" if v }

          arr.join(', ')
        end
    end
  end
end
