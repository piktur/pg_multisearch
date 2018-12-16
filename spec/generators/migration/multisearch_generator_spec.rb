# frozen_string_literal: true

require 'rails_helper'
require 'pg_multisearch/generators/migration/index_generator.rb'

RSpec.describe PgMultisearch::Generators::Migration::IndexGenerator, type: :generator do
  tmp = File.expand_path('tmp', Dir.pwd)
  destination tmp

  before do
    stub_const('Search', double('Search', types: types))

    prepare_destination
    run_generator
  end

  let(:types) { %w(A B C) }
  let(:path) { Dir["#{tmp}/db/migrate/*_create_pg_multisearch_index.rb"][0] }
  let(:contents) { File.read(path) }

  it 'should generate migration' do
    expect(File.exist?(path)).to be(true)
    expect(contents).to start_with("class CreatePgMultisearchIndex < ActiveRecord::Migration")
  end
end
