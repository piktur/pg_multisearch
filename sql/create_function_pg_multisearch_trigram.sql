CREATE OR REPLACE FUNCTION pg_multisearch_trigram(
  jsonb,
  text[] default ARRAY['A']
)
RETURNS text STABLE PARALLEL SAFE STRICT AS $$
BEGIN
  RETURN pg_multisearch_words($1::jsonb, $2, TRUE);
END
$$ LANGUAGE plpgsql;
