CREATE OR REPLACE FUNCTION dmetaphone_to_tsquery(
  text,
  regconfig default 'simple'::regconfig
)
RETURNS tsquery IMMUTABLE AS $$
BEGIN
  IF coalesce($1, '') = '' THEN
    RETURN ''::tsquery;
  ELSE
    RETURN to_tsquery($2, quote_literal($1));
  END IF;
END
$$ LANGUAGE plpgsql;
