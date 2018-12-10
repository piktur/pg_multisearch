# frozen_string_literal: true

module PgMultisearch
  module Features
    extend ::ActiveSupport::Autoload

    autoload :Age
    autoload :Feature
    autoload :TsHeadline
    autoload :TSearch, 'pg_multisearch/features/tsearch'
    autoload :TsQuery
  end
end
