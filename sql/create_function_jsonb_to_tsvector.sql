CREATE OR REPLACE FUNCTION jsonb_to_tsvector(
  regconfig,
  jsonb,
  jsonb default '["all"]'::jsonb
)
RETURNS tsvector AS $$
DECLARE
  constrained bool := ($3 ->> 0) != 'all';
  content text := '';
  value jsonb;
  key text;
BEGIN
  FOR value IN SELECT jsonb_each.value FROM jsonb_each($2) LOOP
    IF NOT constrained OR $3 ? jsonb_typeof(value) THEN
      content = content || ' ' || value::text;
    END IF;
  END LOOP;

  RETURN to_tsvector($1, content);
END
$$ LANGUAGE plpgsql;
