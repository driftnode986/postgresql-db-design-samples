-- 4 案の保存サイズ。本体と索引を分けて出す。
-- 🔴 案ごとに表の数が違うので、案の合計で比べる（一覧の行だけを見て順位を付けない）
SELECT n.nspname AS schema, c.relname AS table_name,
       pg_size_pretty(pg_relation_size(c.oid))      AS heap,
       pg_size_pretty(pg_indexes_size(c.oid))       AS indexes,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total
FROM pg_class AS c JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('ch07_a', 'ch07_b', 'ch07_c', 'ch07_d') AND c.relkind = 'r'
ORDER BY n.nspname, c.relname;

-- 案ごとの合計（これで順位を付ける）
SELECT n.nspname AS schema,
       sum(pg_total_relation_size(c.oid))                  AS total_bytes,
       pg_size_pretty(sum(pg_total_relation_size(c.oid)))  AS total
FROM pg_class AS c JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('ch07_a', 'ch07_b', 'ch07_c', 'ch07_d') AND c.relkind = 'r'
GROUP BY n.nspname ORDER BY sum(pg_total_relation_size(c.oid));
