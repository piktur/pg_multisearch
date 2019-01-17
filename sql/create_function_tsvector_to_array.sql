CREATE OR REPLACE FUNCTION tsvector_to_array(tsvector)
RETURNS text[]%{parallel} STRICT AS $$
BEGIN
  RETURN array_agg(word) FROM ts_stat('SELECT (' || quote_literal(coalesce($1, '')) || ')::tsvector');
END
$$ LANGUAGE plpgsql;
