# frozen_string_literal: true

require 'rails_helper'
require 'pg_multisearch/features/age'

RSpec.describe PgMultsearch::Features::Age do
  with_table "pg_search_documents", {}, &DOCUMENTS_SCHEMA

  with_model :Searchable do
    model do
      include PgSearch
      multisearchable
    end
  end

  with_model :Document do
    table do |t|
      t.string   :content
      t.string   :provenance
      t.tsvector :tsv
    end
  end

  before do
    PgSearch.multisearch_options = {
      using: {
        age: {
          date_column: 'provenance'
        }
      },
      ranked_by: ':age'
    }
  end

  subject { described_class.new(query, options, columns, Document, normalizer) }

  let(:query) { Faker::Lorem.word }
  let(:content) { [query, Faker::Lorem.sentence].join(' ') }
  let(:options) { config.feature_options[:age] }
  let(:config) { PgSearch::Configuration.new(options_proc.call(query), Document) }
  let(:options_proc) do
    ->(query) { { query: query, against: :content }.merge(PgSearch.multisearch_options) }
  end
  let(:normalizer) { PgSearch::Normalizer.new(config) }
  let(:columns) do
    [
      PgSearch::Configuration::Column.new(:content, nil, Document),
    ]
  end
  let(:actual) { subject.rank.to_sql }
  let(:table_name) { Document.quoted_table_name }

  describe '#rank' do
    let(:expected) do
      <<-SQL.strip_heredoc.tr("\n", '')
        (cume_dist() OVER (ORDER BY age(CAST(#{table_name}."provenance" AS TIMESTAMP)) DESC))
      SQL
    end

    it 'should return SQL expression calculating cume_dist of each matched row' do
      expect(actual).to eq(expected)
    end
  end
end
