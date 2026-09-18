-- GIN の作成時間。並列作成の効果を見る
\timing on
DROP INDEX IF EXISTS articles_tags_gin;
SET max_parallel_maintenance_workers = 0;
CREATE INDEX articles_tags_gin_serial ON articles USING gin (tags);
DROP INDEX articles_tags_gin_serial;
RESET max_parallel_maintenance_workers;
CREATE INDEX articles_tags_gin ON articles USING gin (tags);
