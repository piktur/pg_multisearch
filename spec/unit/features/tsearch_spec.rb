# frozen_string_literal: true

require 'rails_helper'
require 'pg_multisearch/strategies/tsearch'

RSpec.describe PgMultisearch::Strategies::Tsearch do
  with_table "pg_multisearch_index", {}, &DOCUMENTS_SCHEMA

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
  #   PgMultisearch.config = {
  #     strategies: {
  #       age: {
  #         date_column: 'provenance'
  #       }
  #     },
  #     rank_by: ':age'
  #   }
  # end

  subject { described_class.new(query, options, columns, Document, normalizer) }

  let(:query) { 'query' }
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
