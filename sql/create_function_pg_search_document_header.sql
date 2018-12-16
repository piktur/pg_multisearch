CREATE OR REPLACE FUNCTION pg_search_document_header(
  jsonb,
  text[] default ARRAY['A']
)
RETURNS text IMMUTABLE AS $$
BEGIN
  RETURN pg_search_words($1::jsonb, $2, TRUE);
END
$$ LANGUAGE plpgsql;
