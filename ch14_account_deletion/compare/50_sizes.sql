-- run-as: book_app
-- 3 案のサイズ。個人情報を分けると表が増えるので、合計で比べる。
SELECT 'A 論理削除' AS plan,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS total
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'ch14_a' AND c.relkind = 'r'
UNION ALL
SELECT 'B 物理削除+控え',
       pg_size_pretty(sum(pg_total_relation_size(c.oid)))
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'ch14_b' AND c.relkind = 'r'
UNION ALL
SELECT 'C 個人情報を分離',
       pg_size_pretty(sum(pg_total_relation_size(c.oid)))
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'ch14_c' AND c.relkind = 'r'
ORDER BY 1;

-- 内訳（バイト）。図の数値はここから取る。
SELECT n.nspname AS schema, c.relname AS tbl,
       pg_total_relation_size(c.oid) AS total_bytes
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('ch14_a','ch14_b','ch14_c') AND c.relkind = 'r'
ORDER BY n.nspname, c.relname;
