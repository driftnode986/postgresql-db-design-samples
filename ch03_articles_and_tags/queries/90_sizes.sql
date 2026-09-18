-- 案ごとの保存サイズ。本体とインデックスを分けて出す
SELECT c.relname,
       pg_size_pretty(pg_relation_size(c.oid))        AS heap,
       pg_size_pretty(pg_indexes_size(c.oid))         AS indexes,
       pg_size_pretty(pg_total_relation_size(c.oid))  AS total
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = current_schema() AND c.relkind = 'r'
ORDER BY pg_total_relation_size(c.oid) DESC;

-- インデックスごとの内訳
SELECT i.relname, pg_size_pretty(pg_relation_size(i.oid)) AS size
FROM pg_class i JOIN pg_namespace n ON n.oid = i.relnamespace
WHERE n.nspname = current_schema() AND i.relkind = 'i'
ORDER BY pg_relation_size(i.oid) DESC;
