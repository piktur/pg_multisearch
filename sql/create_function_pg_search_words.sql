CREATE OR REPLACE FUNCTION pg_search_words(
  jsonb,
  "char" default 'A',
  bool default 't'
)
RETURNS text AS $$
DECLARE
  tsv tsvector;
  lexemes text[];
BEGIN
  tsv = jsonb_to_tsvector('simple', $1 -> $2, '["string"]'::jsonb);
  lexemes = tsvector_to_array(tsv);

  IF $3 THEN
    RETURN array_to_string(lexemes, ' '::text);
  ELSE
    RETURN lexemes;
  END IF;
END
$$ LANGUAGE plpgsql;
