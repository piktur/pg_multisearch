# frozen_string_literal: true

require 'with_model'

DOCUMENTS_SCHEMA = lambda do |t|
  t.belongs_to :searchable, polymorphic: true
  t.jsonb      :content
  t.jsonb      :data
  t.datetime   :provenance
  t.tsvector   :tsv
  t.tsvector   :header
end

RSpec.configure do |config|
  config.extend WithModel
end
