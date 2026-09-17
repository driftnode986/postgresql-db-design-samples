-- 全件を読む集計。Buffers の shared hit と read を見る
EXPLAIN (ANALYZE)
SELECT product_id, sum(qty)
FROM order_items
GROUP BY product_id;
