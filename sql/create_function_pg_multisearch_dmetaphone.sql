CREATE OR REPLACE FUNCTION pg_multisearch_dmetaphone(
  jsonb,
  text[] default ARRAY['A']
)
RETURNS tsvector STABLE PARALLEL SAFE STRICT AS $$
DECLARE
  t record;
  weight text;
  weighted jsonb;
  filter jsonb := '["string"]'::jsonb;
  codes text := '';
  tsv tsvector := ''::tsvector;
  tsv_fragment tsvector;
BEGIN
  FOREACH weight IN ARRAY $2 LOOP
    weighted := $1::jsonb -> weight;

    CONTINUE WHEN (weighted IS NULL) OR (weighted IN ('""', 'null', '{}'));

    FOR t IN SELECT * FROM jsonb_each(weighted) LOOP
      CONTINUE WHEN
        (t.value IS NULL) OR
        (t.value IN ('""', 'null')) OR NOT
        (filter ? jsonb_typeof(t.value));

      codes := codes || ' ' || string_to_dmetaphone(t.value::text);
    END LOOP;

    tsv_fragment := dmetaphone_to_tsvector(trim(leading ' ' from codes));

    codes := ''; -- clear before next iteration

    CONTINUE WHEN (tsv_fragment IS NULL) OR (tsv_fragment = '');

    tsv := tsv || setweight(tsv_fragment, weight::"char");
  END LOOP;

  RETURN tsv;
END
$$ LANGUAGE plpgsql;
