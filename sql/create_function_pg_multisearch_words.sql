CREATE OR REPLACE FUNCTION pg_multisearch_words(
  jsonb,
  text[] default ARRAY['A'],
  bool default TRUE
)
RETURNS text STABLE PARALLEL SAFE STRICT AS $$
DECLARE
  weight text;
  tsv tsvector := ''::tsvector;
  lexemes text[];
  filter jsonb := '["string"]'::jsonb;
BEGIN
  FOREACH weight IN ARRAY $2 LOOP
    tsv := tsv || jsonb_to_tsvector('simple', $1 -> weight, filter);
  END LOOP;

  lexemes = tsvector_to_array(tsv);

  IF $3 THEN
    RETURN array_to_string(lexemes, ' '::text);
  ELSE
    RETURN lexemes;
  END IF;
END
$$ LANGUAGE plpgsql;
