-- SIZE=S は 10 万行、M は 100 万行、L は 500 万行（L は shared_buffers の 128MB を超える量）
SELECT CASE :'size' WHEN 'S' THEN 100000 WHEN 'M' THEN 1000000 ELSE 5000000 END AS n \gset

\timing on
-- インデックスは、データを入れた後に作り直す。付けたまま入れると、同じデータでも
-- インデックスのサイズが大きくなる（指標2 で確かめる）
DROP INDEX IF EXISTS ch01.order_items_product_idx;
TRUNCATE ch01.order_items;
-- 乱数の種を固定する。同じ種なら、同じセッションでは同じ乱数の並びになる
SELECT setseed(0.42);
-- power(random(), 3) で、番号の小さい商品に注文を集中させる（1 万商品）
INSERT INTO ch01.order_items (product_id, qty, ordered_at)
SELECT 1 + floor(power(random(), 3) * 10000)::int,
       random(1, 5),
       '2026-01-01 00:00+09'::timestamptz + g * interval '1 second'
FROM generate_series(1, :n) AS g;

CREATE INDEX order_items_product_idx
  ON ch01.order_items (product_id, ordered_at);
VACUUM (ANALYZE) ch01.order_items;
