# frozen_string_literal: true

module PgMultisearch
  module Configuration
    extend ::ActiveSupport::Autoload

    autoload :Base
    autoload :Filter
    autoload :Indexable
    autoload :Options
    autoload :Rank
    autoload :Scopes
    autoload :Strategies

    COMMON_KEYS = %i(only rank_only).freeze

    INVALID_COLUMN_SELECTION_MSG = <<-MSG.freeze
      Column selection is invalid. Ensure all columns referenced by `filter_by` and `rank_by`
      strategies are included in `against`, or if `stratategies.<strategy_name>.only` specified,
      that it also includes the referenced columns.
    MSG
    private_constant :INVALID_COLUMN_SELECTION_MSG

    class ConfigurationError < ::StandardError; end

    class ValidationError < ConfigurationError
      def initialize(key, val)
        @key = key
        @val = val
      end

      def message
        "Invalid value `#{@val}` given for `#{@key}`"
      end
    end
  end
end
