CREATE OR REPLACE FUNCTION pg_multisearch_words(
  jsonb,
  text[] default ARRAY['A'],
  bool default TRUE
)
RETURNS text STABLE%{parallel} STRICT AS $$
DECLARE
  weight text;
  weighted jsonb;
  tsv tsvector := ''::tsvector;
  lexemes text[];
  filter jsonb := '["string"]'::jsonb;
BEGIN
  FOREACH weight IN ARRAY $2 LOOP
    weighted := $1 -> weight;

    CONTINUE WHEN weighted IN ('{}', 'null');

    tsv := tsv || coalesce(jsonb_to_tsvector('simple', weighted, filter), '');
  END LOOP;

  lexemes := tsvector_to_array(tsv);

  IF $3 THEN
    RETURN array_to_string(lexemes, ' '::text);
  ELSE
    RETURN lexemes;
  END IF;
END
$$ LANGUAGE plpgsql;
