CREATE OR REPLACE FUNCTION tsvector_to_array(tsvector)
RETURNS text[] IMMUTABLE AS $$
BEGIN
  RETURN array_agg(word) FROM ts_stat('SELECT (' || quote_literal(to_tsvector('Eaton Vance')) || ')::tsvector');
END
$$ LANGUAGE plpgsql;
