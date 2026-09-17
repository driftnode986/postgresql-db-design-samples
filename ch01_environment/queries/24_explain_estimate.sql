-- 見積もりの行数（rows=）と、実際の行数（actual の rows=）を比べる
EXPLAIN (ANALYZE)
SELECT count(*) FROM order_items WHERE product_id = 1;
