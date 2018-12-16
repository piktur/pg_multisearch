CREATE OR REPLACE FUNCTION pg_search_document_content(jsonb)
RETURNS tsvector IMMUTABLE AS $$
DECLARE
  weight text;
  weights text[] := ARRAY['A','B','C','D'];
  tsvector tsvector := ''::tsvector;
  filter jsonb := '["string"]'::jsonb;
BEGIN
  FOREACH weight IN ARRAY weights LOOP
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
