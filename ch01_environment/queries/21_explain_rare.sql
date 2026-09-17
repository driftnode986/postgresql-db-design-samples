-- 注文が少ない商品で、同じ問い合わせ
EXPLAIN (ANALYZE)
SELECT id, qty, ordered_at
FROM order_items
WHERE product_id = 9000
ORDER BY ordered_at DESC
LIMIT 20;
