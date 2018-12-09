SELECT jsonb_to_tsvector(
  'simple',
  content::jsonb -> 'A',
  '["string"]'::jsonb
)
FROM pg_search_documents
