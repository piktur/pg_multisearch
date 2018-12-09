ALTER TABLE pg_search_documents
ALTER COLUMN searchable_type TYPE searchable
USING searchable_type::searchable;
