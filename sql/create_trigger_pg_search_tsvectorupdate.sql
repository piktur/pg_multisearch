CREATE TRIGGER pg_search_tsvectorupdate BEFORE INSERT OR UPDATE
ON pg_search_documents FOR EACH ROW EXECUTE PROCEDURE pg_search_document();
