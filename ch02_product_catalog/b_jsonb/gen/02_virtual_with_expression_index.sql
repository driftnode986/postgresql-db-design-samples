-- run-as: book_owner
-- VIRTUAL の生成列にはインデックスを付けられないが、同じ式の式インデックスは使われる。
-- VIRTUAL の生成列には統計が無いので、式インデックスを作ったあとに ANALYZE して式の統計を取る
BEGIN;
ALTER TABLE ch02_b.products
  ADD COLUMN color text GENERATED ALWAYS AS (attrs->>'color') VIRTUAL,
  ADD COLUMN size  text GENERATED ALWAYS AS (attrs->>'size')  VIRTUAL;

EXPLAIN (ANALYZE)
SELECT id FROM products WHERE color = 'teal';

CREATE INDEX products_color_size_expr_idx
  ON ch02_b.products ((attrs->>'color'), (attrs->>'size'), created_at DESC);
ANALYZE ch02_b.products;

EXPLAIN (ANALYZE)
SELECT id FROM products WHERE color = 'teal';

EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE color = 'yellow' AND size = 'XL'
ORDER BY created_at DESC
LIMIT 20;
ROLLBACK;
