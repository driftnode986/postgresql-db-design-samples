-- 人気の商品（注文が多い）の、直近の注文 20 件
EXPLAIN (ANALYZE)
SELECT id, qty, ordered_at
FROM order_items
WHERE product_id = 1
ORDER BY ordered_at DESC
LIMIT 20;
