CREATE OR REPLACE FUNCTION pg_multisearch_content(
  jsonb,
  text[] default ARRAY['A','B','C','D']
)
RETURNS tsvector STABLE PARALLEL SAFE STRICT AS $$
DECLARE
  weight text;
  tsvector tsvector := ''::tsvector;
  filter jsonb := '["string"]'::jsonb;
BEGIN
  FOREACH weight IN ARRAY $2 LOOP
    tsvector := tsvector || setweight(
      jsonb_to_tsvector(
        get_current_ts_config(),
        $1::jsonb -> weight,
        filter
      ),
      weight::"char"
    );
  END LOOP;

  RETURN tsvector;
END
$$ LANGUAGE plpgsql;
