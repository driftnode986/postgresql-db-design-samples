-- run-as: book_owner
-- GIN インデックスの 2 つの種類（演算子クラス）で、サイズと、使える検索を比べる
\timing on
BEGIN;
-- 演算子クラスを書かなければ、既定の jsonb_ops になる
CREATE INDEX products_attrs_ops ON ch02_b.products USING gin (attrs);
SELECT pg_size_pretty(pg_relation_size('ch02_b.products_attrs_ops'))
         AS jsonb_ops,
       pg_size_pretty(pg_relation_size('ch02_b.products_attrs_path'))
         AS jsonb_path_ops;

-- 2 つの GIN インデックスがある状態で
-- ?（そのキーを持つか）は jsonb_ops だけが使える
EXPLAIN (ANALYZE) SELECT id FROM products WHERE attrs ? 'noise_db';
-- 数値の大小の比較には、どちらも使われない
EXPLAIN (ANALYZE) SELECT id FROM products WHERE attrs @? '$.watt ? (@ > 1400)';

-- jsonb_path_ops だけの状態で
DROP INDEX ch02_b.products_attrs_ops;
EXPLAIN (ANALYZE) SELECT id FROM products WHERE attrs ? 'noise_db';
-- 等しいという条件には使われるが、大小の比較には使われない
EXPLAIN (ANALYZE) SELECT id FROM products WHERE attrs @? '$.watt ? (@ == 1400)';
EXPLAIN (ANALYZE) SELECT id FROM products WHERE attrs @? '$.watt ? (@ > 1400)';
ROLLBACK;
