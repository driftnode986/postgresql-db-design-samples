-- 親の行数。SIZE=S は 2 万、M は 20 万、L は 100 万。子は親 1 行につき明細 3・支払い 1・出荷 1
SELECT CASE :'size' WHEN 'S' THEN 20000 WHEN 'M' THEN 200000 ELSE 1000000 END AS n \gset

-- 3 組に同じ手順で入れる。親を時刻順に入れ、子は親の時刻順に入れる（挿入順を固定する）
INSERT INTO ch01.b_orders (ordered_at)
SELECT '2026-01-01 00:00+09'::timestamptz + g * interval '1 second'
FROM generate_series(1, :n) AS g;
INSERT INTO ch01.b_items (order_id, qty)
SELECT o.id, k FROM ch01.b_orders o, generate_series(1, 3) AS k ORDER BY o.ordered_at, k;
INSERT INTO ch01.b_payments (order_id, amount)
SELECT id, 1000 FROM ch01.b_orders ORDER BY ordered_at;
INSERT INTO ch01.b_shipments (order_id, shipped_at)
SELECT id, ordered_at + interval '1 day' FROM ch01.b_orders ORDER BY ordered_at;

INSERT INTO ch01.u7_orders (ordered_at)
SELECT '2026-01-01 00:00+09'::timestamptz + g * interval '1 second'
FROM generate_series(1, :n) AS g;
INSERT INTO ch01.u7_items (order_id, qty)
SELECT o.id, k FROM ch01.u7_orders o, generate_series(1, 3) AS k ORDER BY o.ordered_at, k;
INSERT INTO ch01.u7_payments (order_id, amount)
SELECT id, 1000 FROM ch01.u7_orders ORDER BY ordered_at;
INSERT INTO ch01.u7_shipments (order_id, shipped_at)
SELECT id, ordered_at + interval '1 day' FROM ch01.u7_orders ORDER BY ordered_at;

INSERT INTO ch01.u4_orders (ordered_at)
SELECT '2026-01-01 00:00+09'::timestamptz + g * interval '1 second'
FROM generate_series(1, :n) AS g;
INSERT INTO ch01.u4_items (order_id, qty)
SELECT o.id, k FROM ch01.u4_orders o, generate_series(1, 3) AS k ORDER BY o.ordered_at, k;
INSERT INTO ch01.u4_payments (order_id, amount)
SELECT id, 1000 FROM ch01.u4_orders ORDER BY ordered_at;
INSERT INTO ch01.u4_shipments (order_id, shipped_at)
SELECT id, ordered_at + interval '1 day' FROM ch01.u4_orders ORDER BY ordered_at;

VACUUM (ANALYZE) ch01.b_orders, ch01.b_items, ch01.b_payments, ch01.b_shipments,
  ch01.u7_orders, ch01.u7_items, ch01.u7_payments, ch01.u7_shipments,
  ch01.u4_orders, ch01.u4_items, ch01.u4_payments, ch01.u4_shipments;
