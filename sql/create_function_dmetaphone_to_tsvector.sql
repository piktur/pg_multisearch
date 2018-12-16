CREATE OR REPLACE FUNCTION dmetaphone_to_tsvector(
  text,
  regconfig default 'simple'::regconfig
)
RETURNS tsvector IMMUTABLE AS $$
BEGIN
  RETURN to_tsvector($2, coalesce($1, ''));
END
$$ LANGUAGE plpgsql;
