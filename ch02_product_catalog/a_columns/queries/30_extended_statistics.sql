-- run-as: book_owner
-- 色とサイズは「衣料のときだけ両方に値が入る」ので、独立ではない。
-- 列の組の統計（拡張統計）を足すと、見積もりがどう変わるかを見る。
-- ほかの測定に影響しないように、最後に ROLLBACK で元に戻す
BEGIN;
CREATE STATISTICS products_color_size (mcv) ON color, size FROM ch02_a.products;
ANALYZE ch02_a.products;

EXPLAIN (ANALYZE)
SELECT id
FROM products
WHERE color = 'black' AND size = 'M';
ROLLBACK;
