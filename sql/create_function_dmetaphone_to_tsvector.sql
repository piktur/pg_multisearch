CREATE OR REPLACE FUNCTION dmetaphone_to_tsvector(
  text,
  regconfig default 'simple'::regconfig
)
RETURNS tsvector STABLE PARALLEL SAFE STRICT AS $$ -- Cannot tag as IMMUTABLE; `to_tsvector` is tagged STABLE
BEGIN
  RETURN to_tsvector($2, coalesce($1, ''));
END
$$ LANGUAGE plpgsql;
