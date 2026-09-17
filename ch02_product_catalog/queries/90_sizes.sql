-- 保存サイズ。いま search_path の先頭にあるスキーマのテーブルを全部並べる
SELECT c.relname AS table_name,
       pg_size_pretty(pg_relation_size(c.oid))       AS heap,
       pg_size_pretty(pg_indexes_size(c.oid))        AS indexes,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total
FROM pg_class AS c
WHERE c.relnamespace = current_schema()::regnamespace AND c.relkind = 'r'
ORDER BY c.relname;

SELECT pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS schema_total
FROM pg_class AS c
WHERE c.relnamespace = current_schema()::regnamespace AND c.relkind = 'r';
