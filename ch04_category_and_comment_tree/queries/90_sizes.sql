-- 案ごとの保存サイズ。本体とインデックスを分けて出す
SELECT c.relname AS object,
       pg_size_pretty(pg_relation_size(c.oid))       AS heap,
       pg_size_pretty(pg_indexes_size(c.oid))        AS indexes,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total,
       c.reltuples::bigint                           AS rows
FROM pg_class c
WHERE c.relnamespace = current_schema()::regnamespace
  AND c.relkind = 'r'
ORDER BY c.relname;

-- インデックスごとの内訳
SELECT indexrelname AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE schemaname = current_schema()
ORDER BY pg_relation_size(indexrelid) DESC;

-- スキーマ全体
SELECT pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS schema_total
FROM pg_class c
WHERE c.relnamespace = current_schema()::regnamespace AND c.relkind = 'r';
