CREATE TRIGGER pg_multisearch_tsvectorupdate BEFORE INSERT OR UPDATE
ON %{table_name} FOR EACH ROW EXECUTE PROCEDURE pg_multisearch_content();
