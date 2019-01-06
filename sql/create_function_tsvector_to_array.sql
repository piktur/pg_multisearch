CREATE OR REPLACE FUNCTION tsvector_to_array(tsvector)
RETURNS text[] PARALLEL SAFE STRICT AS $$
BEGIN
  RETURN array_agg(word) FROM ts_stat('SELECT (' || quote_literal($1) || ')::tsvector');
END
$$ LANGUAGE plpgsql;
