-- 商品を 3 つ指定する。Index Searches が、インデックスを引き直した回数を示す
EXPLAIN (ANALYZE)
SELECT count(*)
FROM order_items
WHERE product_id IN (1, 2, 3)
  AND ordered_at >= '2026-01-05 00:00+09';
