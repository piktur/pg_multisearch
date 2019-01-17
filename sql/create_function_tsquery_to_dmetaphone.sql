CREATE OR REPLACE FUNCTION tsquery_to_dmetaphone(text)
RETURNS text IMMUTABLE%{parallel} STRICT AS $$
DECLARE
  t text;
  codes text := '' || $1;
BEGIN
  FOR t IN SELECT regexp_matches[1] FROM regexp_matches($1, '(\w+)(?:[\s:]?[\*]?[A-D]*)', 'gi') LOOP
    codes := replace(codes, t, dmetaphone(t));
  END LOOP;

  RETURN codes;
END
$$ LANGUAGE plpgsql;
