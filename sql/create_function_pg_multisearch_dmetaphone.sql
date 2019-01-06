CREATE OR REPLACE FUNCTION pg_multisearch_dmetaphone(
  jsonb,
  text[] default ARRAY['A']
)
RETURNS tsvector STABLE PARALLEL SAFE STRICT AS $$
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

    tsvector := tsvector || setweight(
      dmetaphone_to_tsvector(
        quote_literal(
          trim(leading ' ' from codes)
        )
      ),
      weight::"char"
    );
  END LOOP;

  RETURN tsvector;
END
$$ LANGUAGE plpgsql;
