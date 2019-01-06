ALTER TABLE %{table_name}
ALTER COLUMN searchable_type TYPE searchable
USING searchable_type::text::searchable;
