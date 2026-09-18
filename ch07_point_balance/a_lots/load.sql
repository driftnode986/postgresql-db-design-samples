-- 元データを写す。
-- 🔴 案ごとに別々に生成すると乱数が変わって比較にならないので、ch07_r から ORDER BY id で写す。
SELECT count(*) AS src_rows FROM ch07_r.src_txn \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch07_a.lot_consumptions, ch07_a.point_txns, ch07_a.point_lots
  RESTART IDENTITY CASCADE;

-- 台帳は付与も利用もそのまま写す
INSERT INTO ch07_a.point_txns (id, user_id, kind, amount, created_at)
OVERRIDING SYSTEM VALUE
SELECT id, user_id, kind, amount, created_at
FROM ch07_r.src_txn ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch07_a.point_txns', 'id'),
              (SELECT max(id) FROM ch07_a.point_txns));

-- ロットは付与の行から作る。
-- 🔴 ここでは remaining = granted のまま入れる（まだ何も使っていない状態）。
--    利用ぶんの消し込みは、測定の前に 10_consume_initial.sql でまとめて行う。
--    投入と消し込みを分けるのは、投入時間そのものを案ごとに比べるためである
INSERT INTO ch07_a.point_lots (id, user_id, granted, remaining, expires_at, granted_at)
OVERRIDING SYSTEM VALUE
SELECT id, user_id, amount, amount, expires_at, created_at
FROM ch07_r.src_txn WHERE kind = 'grant' ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch07_a.point_lots', 'id'),
              (SELECT max(id) FROM ch07_a.point_lots));

ANALYZE ch07_a.point_lots, ch07_a.point_txns, ch07_a.lot_consumptions;

SELECT count(*) AS lots, sum(remaining) AS total_remaining FROM ch07_a.point_lots;
