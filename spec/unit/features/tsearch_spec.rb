# frozen_string_literal: true

require 'rails_helper'
require 'pg_multisearch/features/tsearch'

RSpec.describe PgMultisearch::Features::TSearch do
  with_table "pg_search_documents", {}, &DOCUMENTS_SCHEMA

  with_model :Searchable do
    model do
      include PgSearch
      multisearchable against: { title: 'A' }
    end
  end

  with_model :Document do
    table do |t|
      t.string   :content
      t.datetime :provenance
      t.text     :header
      t.tsvector :tsv
    end
  end

  # before do
  #   PgSearch.multisearch_options = {
  #     using: {
  #       age: {
  #         date_column: 'provenance'
  #       }
  #     },
  #     ranked_by: ':age'
  #   }
  # end

  subject { described_class.new(query, options, columns, Document, normalizer) }

  let(:query) { 'query' }
  let(:content) { [query, Faker::Lorem.sentence].join(' ') }
  let(:options) { config.feature_options[:age] }
  let(:config) { PgMultisearch::Configuration.new(options_proc.call(query), Document) }
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
        ts_rank(
          (
            to_tsvector(
              'simple',
              coalesce(#{Model.quoted_table_name}."name"::text, '')
            ) ||
            to_tsvector(
              'simple',
              coalesce(#{Model.quoted_table_name}."content"::text, '')
            )
          ),
          (
            to_tsquery('simple', ''' ' || 'query' || ' ''')
          ),
          0
        )
      SQL
    end

    it 'should return SQL expression calculating using the ts_rank() function' do
      binding.pry

      expect(actual).to eq(expected)
    end
  end

  describe '#call' do
  end
end
