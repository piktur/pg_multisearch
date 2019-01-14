CREATE OR REPLACE FUNCTION jsonb_fields_to_text(
  jsonb,
  text[]
) RETURNS text IMMUTABLE PARALLEL SAFE STRICT AS $$
DECLARE
  path text;
  str text := '';
BEGIN
  FOREACH path IN ARRAY $2 LOOP
    str := str || ' ' || coalesce($1 #>> string_to_array(path, ','), '');
  END LOOP;

  RETURN trim(leading ' ' from str);
END
$$ LANGUAGE plpgsql;
