-- run-as: book_owner
-- STORED の生成列は値をテーブルに保存するので、インデックスも統計も普通の列と同じに使える。
-- 足すときにテーブル全体を書き換える（ファイル番号が変わる）
\timing on
SELECT pg_relation_filenode('ch02_b.products') AS filenode_before \gset
BEGIN;
ALTER TABLE ch02_b.products
  ADD COLUMN color text GENERATED ALWAYS AS (attrs->>'color') STORED,
  ADD COLUMN size  text GENERATED ALWAYS AS (attrs->>'size')  STORED;
SELECT mode FROM pg_locks
WHERE relation = 'ch02_b.products'::regclass AND pid = pg_backend_pid();
SELECT pg_relation_filenode('ch02_b.products') = :filenode_before AS not_rewritten;

CREATE INDEX products_color_size_created
  ON ch02_b.products (color, size, created_at DESC);
ANALYZE ch02_b.products;

EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE color = 'yellow' AND size = 'XL'
ORDER BY created_at DESC
LIMIT 20;
ROLLBACK;
