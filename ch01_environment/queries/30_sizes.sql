-- 保存サイズ。テーブル本体、インデックス、合計を分けて見る
SELECT pg_size_pretty(pg_relation_size('order_items'))       AS heap,
       pg_size_pretty(pg_indexes_size('order_items'))        AS indexes,
       pg_size_pretty(pg_total_relation_size('order_items')) AS total;

-- インデックスの葉のページの充填率（avg_leaf_density）
SELECT leaf_pages, avg_leaf_density, leaf_fragmentation
FROM pgstatindex('order_items_product_idx');
