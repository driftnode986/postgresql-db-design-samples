-- 親子 4 テーブルの合計を、主キーの型ごとに比べる
SELECT split_part(relname, '_', 1) AS pk_type,
       sum(pg_relation_size(oid)) AS heap_bytes,
       sum(pg_indexes_size(oid))  AS index_bytes,
       sum(pg_total_relation_size(oid)) AS total_bytes,
       pg_size_pretty(sum(pg_total_relation_size(oid))) AS total
FROM pg_class
WHERE relnamespace = 'ch01'::regnamespace AND relkind = 'r'
  AND relname ~ '^(b|u7|u4)_(orders|items|payments|shipments)$'
GROUP BY 1
ORDER BY total_bytes;

-- 明細の主キーのインデックスの、葉のページの充填率
SELECT 'b_items' AS table_name, avg_leaf_density FROM pgstatindex('b_items_pkey')
UNION ALL SELECT 'u7_items', avg_leaf_density FROM pgstatindex('u7_items_pkey')
UNION ALL SELECT 'u4_items', avg_leaf_density FROM pgstatindex('u4_items_pkey');
