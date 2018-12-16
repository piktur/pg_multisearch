# frozen_string_literal: true

require 'rails_helper'
require 'pg_multisearch/plugins/suggestiongs/generator/migration/migration_generator.rb'

RSpec.describe PgMultisearch::Suggestions::Generator::InstallGenerator, type: :generator do
  tmp = File.expand_path('tmp', Dir.pwd)
  destination File.expand_path('tmp', Dir.pwd)

  before do
    prepare_destination
    run_generator
  end
end
