# frozen_string_literal: true

require 'rails_helper'
require_relative File.expand_path('lib/pg_multisearch/migration/suggestions_generator.rb', Dir.pwd)

# PgMultisearch::Migration::MultisearchGenerator.start
RSpec.describe PgMultisearch::Migration::SuggestionsGenerator, type: :generator do
  tmp = File.expand_path('tmp', Dir.pwd)
  destination File.expand_path('tmp', Dir.pwd)

  before do
    prepare_destination
    run_generator
  end

  let(:path) { Dir["#{tmp}/db/migrate/*_create_pg_multisearch_suggestions.rb"][0] }
  let(:contents) { File.read(path) }

  it 'should generate migration' do
    expect(File.exist?(path)).to be(true)
    expect(contents).to start_with("class CreatePgMultisearchSuggestions < ActiveRecord::Migration")
  end
end
