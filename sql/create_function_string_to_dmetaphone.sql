CREATE OR REPLACE FUNCTION string_to_dmetaphone(text)
RETURNS text IMMUTABLE PARALLEL SAFE STRICT AS $$
DECLARE
  t text;
  r text := '(\w+)(?:[\s:]?[\*]?[A-D]*)'; -- (?:[\s\!]?)
  f text := 'gi';
  codes text := '' || $1;
BEGIN
  FOR t IN SELECT regexp_matches[1] FROM regexp_matches($1, r, f) LOOP
    codes := replace(codes, t, dmetaphone(t));
  END LOOP;

  RETURN codes;
END
$$ LANGUAGE plpgsql;
