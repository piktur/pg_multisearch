CREATE OR REPLACE FUNCTION pg_search_document_dmetaphone(
  jsonb,
  text[] default ARRAY['A']
)
RETURNS tsvector IMMUTABLE AS $$
DECLARE
  weight text;
  t record;
  data jsonb;
  codes text := '';
  tsvector tsvector := ''::tsvector;
  filter jsonb := '["string"]'::jsonb;
BEGIN
  FOREACH weight IN ARRAY $2 LOOP
    data := $1::jsonb -> weight;

    FOR t IN SELECT * FROM jsonb_each(data) LOOP
      IF filter ? jsonb_typeof(t.value) THEN
        codes := codes || ' ' || string_to_dmetaphone(data ->> t.key);
      END IF;
    END LOOP;
  END LOOP;

  RETURN dmetaphone_to_tsvector(quote_literal(trim(leading ' ' from codes)));
END
$$ LANGUAGE plpgsql;
