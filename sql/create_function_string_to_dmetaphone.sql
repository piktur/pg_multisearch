CREATE OR REPLACE FUNCTION string_to_dmetaphone(text)
RETURNS text IMMUTABLE AS $$
DECLARE
  word text;
  codes text := '';
BEGIN
  FOREACH word IN ARRAY string_to_array($1, ' ') LOOP
    codes := codes || ' ' || dmetaphone(word);
  END LOOP;

  RETURN trim(leading ' ' from codes);
END
$$ LANGUAGE plpgsql;
