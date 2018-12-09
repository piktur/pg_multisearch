CREATE INDEX pg_search_suggestions_idx
ON pg_search_suggestions
USING GIN (word gin_trgm_ops);
