# frozen_string_literal: true

require 'with_model'

DOCUMENTS_SCHEMA = lambda do |t|
  t.belongs_to :searchable, polymorphic: true
  t.jsonb      :data
  t.datetime   :date
  t.tsvector   :content
  t.text       :trigram
  t.text       :dmetaphone
end

RSpec.configure do |config|
  config.extend WithModel
end
