-- 案C の集計が何に比例するかを測る。
-- 商品 1 にだけ引当の行を積み、同じ状態で商品 1 と商品 500 の集計を比べる。
-- テーブル全体の行数ではなく、その商品の履歴の長さに比例することを示す。
\timing on
DELETE FROM ch05_c.inventory_entries WHERE reason = 'allocation';
ANALYZE ch05_c.inventory_entries;

\echo '## 引当 0 行（商品 1）'
EXPLAIN (ANALYZE) SELECT qty FROM ch05_c.available WHERE product_id = 1;

INSERT INTO ch05_c.inventory_entries (product_id, delta, reason)
SELECT 1, -1, 'allocation' FROM generate_series(1, 10000);
ANALYZE ch05_c.inventory_entries;
\echo '## 引当 10,000 行（商品 1）'
EXPLAIN (ANALYZE) SELECT qty FROM ch05_c.available WHERE product_id = 1;

INSERT INTO ch05_c.inventory_entries (product_id, delta, reason)
SELECT 1, -1, 'allocation' FROM generate_series(1, 90000);
ANALYZE ch05_c.inventory_entries;
\echo '## 引当 100,000 行（商品 1）'
EXPLAIN (ANALYZE) SELECT qty FROM ch05_c.available WHERE product_id = 1;

\echo '## 同じ状態で、履歴の短い商品 500 を測る（インデックスは効いている）'
EXPLAIN (ANALYZE) SELECT coalesce(sum(delta), 0) FROM ch05_c.inventory_entries WHERE product_id = 500;
\echo '## 同じ状態の商品 1（テーブルの 9 割を占めるので Seq Scan が選ばれる）'
EXPLAIN (ANALYZE) SELECT coalesce(sum(delta), 0) FROM ch05_c.inventory_entries WHERE product_id = 1;
