CREATE TABLE pg_search_suggestions AS
SELECT word FROM ts_stat(%{ruby});
