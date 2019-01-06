CREATE INDEX %{table_name}_trigram_idx
ON %{table_name}
USING GIN (trigram gin_trgm_ops);
