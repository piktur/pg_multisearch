# frozen_string_literal: true

require 'rails_helper'
require_relative File.expand_path('lib/pg_multisearch/migration/multisearch_generator.rb', Dir.pwd)

# PgMultisearch::Migration::MultisearchGenerator.start
RSpec.describe PgMultisearch::Migration::MultisearchGenerator, type: :generator do
  tmp = File.expand_path('tmp', Dir.pwd)
  destination tmp

  before do
    stub_const('Search', double('Search', types: types))

    prepare_destination
    run_generator
  end

  let(:types) { %w(A B C) }
  let(:path) { Dir["#{tmp}/db/migrate/*_create_pg_multisearch_documents.rb"][0] }
  let(:contents) { File.read(path) }

  it 'should generate migration' do
    expect(File.exist?(path)).to be(true)
    expect(contents).to start_with("class CreatePgMultisearchDocuments < ActiveRecord::Migration")
  end
end
