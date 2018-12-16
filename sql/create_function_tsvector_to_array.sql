CREATE FUNCTION tsvector_to_array(tsvector)
RETURNS text[] IMMUTABLE AS $$
BEGIN
  SELECT array_agg(word) FROM ts_stat('SELECT $1');
END
$$ LANGUAGE plpgsql;
