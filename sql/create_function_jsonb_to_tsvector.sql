CREATE OR REPLACE FUNCTION jsonb_to_tsvector(
  regconfig,
  jsonb,
  jsonb default '["all"]'::jsonb
)
RETURNS tsvector IMMUTABLE%{parallel} STRICT AS $$
DECLARE
  unconstrained bool := ($3 ->> 0) = 'all';
  content text := '';
  t record;
BEGIN
  FOR t IN SELECT * FROM jsonb_each($2) LOOP
    IF unconstrained OR ($3 ? jsonb_typeof(t.value)) THEN
      CONTINUE WHEN t.value IN ('""', 'null');

      content := content || ' ' || ($2 ->> t.key);
    END IF;
  END LOOP;

  content := trim(leading ' ' from content);

  RETURN to_tsvector($1, content);
END
$$ LANGUAGE plpgsql;
