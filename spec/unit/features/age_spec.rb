# frozen_string_literal: true

require 'rails_helper'
require 'pg_multisearch/strategies/age'

RSpec.describe PgMultsearch::Strategies::Age do
  with_table "pg_multisearch_index", {}, &DOCUMENTS_SCHEMA

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
      t.tsvector :tsvs
    end
  end

  before do
    PgMultisearch.config = {
      strategies: {
        age: {
          date_column: 'provenance'
        }
      },
      rank_by: ':age'
    }
  end

  subject { described_class.new(query, options, columns, Document, normalizer) }

  let(:query) { Faker::Lorem.word }
  let(:content) { [query, Faker::Lorem.sentence].join(' ') }
  let(:options) { config.strategies[:age] }
  let(:config) { PgMultisearch::Configuration.new(options_proc.call(query), Document) }
  let(:options_proc) do
    ->(query) { { query: query, against: :content }.merge(PgMultisearch.config) }
  end
  let(:normalizer) { PgMultisearch::Strategies::Normalizer.new(config) }
  let(:columns) do
    [
      PgMultisearch::Configuration::Column.new(:content, nil, Document),
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
