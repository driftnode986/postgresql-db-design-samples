-- 元データを写す。案A と同じ行を、同じ順で入れる
SELECT count(*) AS src_rows FROM ch07_r.src_txn \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch07_b.lot_consumptions, ch07_b.point_txns, ch07_b.point_lots,
         ch07_b.point_balances RESTART IDENTITY CASCADE;

INSERT INTO ch07_b.point_txns (id, user_id, kind, amount, created_at)
OVERRIDING SYSTEM VALUE
SELECT id, user_id, kind, amount, created_at
FROM ch07_r.src_txn ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch07_b.point_txns', 'id'),
              (SELECT max(id) FROM ch07_b.point_txns));

INSERT INTO ch07_b.point_lots (id, user_id, granted, remaining, expires_at, granted_at)
OVERRIDING SYSTEM VALUE
SELECT id, user_id, amount, amount, expires_at, created_at
FROM ch07_r.src_txn WHERE kind = 'grant' ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch07_b.point_lots', 'id'),
              (SELECT max(id) FROM ch07_b.point_lots));

-- 残高の列は、ロットの残りの合計に合わせて作る。
-- 🔴 この時点では案A の残高と必ず一致する。測定で食い違いが出たら、それは測定中に起きたものである
INSERT INTO ch07_b.point_balances (user_id, balance)
SELECT user_id, sum(remaining)
FROM ch07_b.point_lots
GROUP BY user_id;

ANALYZE ch07_b.point_balances, ch07_b.point_lots,
        ch07_b.point_txns, ch07_b.lot_consumptions;

SELECT count(*) AS balances, sum(balance) AS total_balance FROM ch07_b.point_balances;
