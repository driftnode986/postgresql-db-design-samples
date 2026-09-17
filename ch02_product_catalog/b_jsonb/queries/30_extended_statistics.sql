-- run-as: book_owner
-- ->> で取り出した値には統計が無い。式を対象にした拡張統計を足すと、
-- 見積もりと、選ばれる実行計画がどう変わるかを見る。インデックスは足さない。
-- ほかの測定に影響しないように、最後に ROLLBACK で元に戻す
BEGIN;
CREATE STATISTICS products_color_size_expr (mcv)
  ON (attrs->>'color'), (attrs->>'size') FROM ch02_b.products;
ANALYZE ch02_b.products;

EXPLAIN (ANALYZE)
SELECT id
FROM products
WHERE attrs->>'color' = 'black' AND attrs->>'size' = 'M';

EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE attrs->>'color' = 'black' AND attrs->>'size' = 'M'
ORDER BY created_at DESC
LIMIT 20;
ROLLBACK;
