CREATE OR REPLACE FUNCTION pg_search_document() RETURNS trigger AS $$
DECLARE
  weight "char";
  weights "char"[] := ARRAY['A','B','C','D'];
  qualifier "char" := weights[1];
  tsv tsvector := ''::tsvector;
  filter jsonb := '["string"]'::jsonb;
BEGIN
  FOREACH weight IN ARRAY weights LOOP
    tsv = tsv || setweight(
      jsonb_to_tsvector(
        get_current_ts_config(),
        NEW.content::jsonb -> weight,
        filter
      ),
      weight
    );
  END LOOP;

  NEW.header := pg_search_words(NEW.content::jsonb, qualifier, 't'::bool);
  NEW.tsv    := tsv;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;
