CREATE OR REPLACE FUNCTION dmetaphone_to_tsquery(
  text,
  regconfig default 'simple'::regconfig
)
RETURNS tsquery STABLE PARALLEL SAFE STRICT AS $$ -- Cannot tag as IMMUTABLE; `to_tsquery` is tagged STABLE
BEGIN
  IF coalesce($1, '') = '' THEN
    RETURN ''::tsquery;
  ELSE
    RETURN to_tsquery($2, quote_literal($1));
  END IF;
END
$$ LANGUAGE plpgsql;
