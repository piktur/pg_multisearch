# frozen_string_literal: true

module PgMultisearch::Suggestions::Generators
  class InstallGenerator < ::Rails::Generators::Base
    include ::PgMultisearch::Generators::Install

    hide!

    source_root ::File.expand_path('templates', __dir__)

    argument(:name, type: :string, default: 'Search')

    def add_scope_to_model # rubocop:disable MethodLength
      inject_into_file(
        model_path,
        after: "  include ::PgMultisearch::Search\n",
      ) do
        <<-RUBY

  def suggestions(**options)
    super do |current_scope, builder|
      # apply further scope refinements here
    end
  end
        RUBY
      end
    end

    def add_plugin_to_initializer
      super(:suggestions)
    end
  end
end
