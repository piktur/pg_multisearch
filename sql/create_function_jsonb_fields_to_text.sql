CREATE OR REPLACE FUNCTION jsonb_fields_to_text(
  jsonb,
  text[]
) RETURNS text IMMUTABLE PARALLEL SAFE STRICT AS $$
DECLARE
  path text;
  headline text := '';
BEGIN
  FOREACH path IN ARRAY $2 LOOP
    headline := headline || ' ' || coalesce($1 #>> string_to_array(path, ','), '');
  END LOOP;

  RETURN trim(leading ' ' from headline);
END
$$ LANGUAGE plpgsql;
