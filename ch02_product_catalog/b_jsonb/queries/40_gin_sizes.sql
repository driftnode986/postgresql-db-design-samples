-- run-as: book_owner
-- GIN インデックスの 2 つの種類（演算子クラス）で、サイズと、使える検索を比べる
\timing on
BEGIN;
CREATE INDEX products_attrs_ops ON ch02_b.products USING gin (attrs);  -- 既定は jsonb_ops
SELECT pg_size_pretty(pg_relation_size('ch02_b.products_attrs_ops'))  AS jsonb_ops,
       pg_size_pretty(pg_relation_size('ch02_b.products_attrs_path')) AS jsonb_path_ops;

-- ?（そのキーを持つか）は jsonb_ops だけが使える
EXPLAIN (ANALYZE) SELECT id FROM products WHERE attrs ? 'noise_db';
DROP INDEX ch02_b.products_attrs_ops;
EXPLAIN (ANALYZE) SELECT id FROM products WHERE attrs ? 'noise_db';

-- 数値の大小の比較は、どちらの GIN でも使えない
EXPLAIN (ANALYZE) SELECT id FROM products WHERE attrs @? '$.watt ? (@ == 1400)';
EXPLAIN (ANALYZE) SELECT id FROM products WHERE attrs @? '$.watt ? (@ > 1400)';
ROLLBACK;
