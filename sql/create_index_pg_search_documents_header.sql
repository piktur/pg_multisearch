CREATE INDEX pg_search_documents_header_idx
ON pg_search_documents
USING GIN (header gin_trgm_ops);
