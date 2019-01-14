CREATE OR REPLACE FUNCTION string_to_dmetaphone(text)
RETURNS text IMMUTABLE PARALLEL SAFE STRICT AS $$
DECLARE
  word text;
  code text;
  codes text := '';
BEGIN
  FOREACH word IN ARRAY string_to_array($1, ' ') LOOP
    code := dmetaphone(word);

    CONTINUE WHEN (code IS NULL) OR (code = '');

    codes := codes || ' ' || code;
  END LOOP;

  RETURN trim(leading ' ' from codes);
END
$$ LANGUAGE plpgsql;
