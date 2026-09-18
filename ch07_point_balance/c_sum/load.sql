-- 元データを写す。案A・案B と同じ行を、同じ順で入れる
SELECT count(*) AS src_rows FROM ch07_r.src_txn \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch07_c.point_txns RESTART IDENTITY CASCADE;

INSERT INTO ch07_c.point_txns (id, user_id, kind, amount, expires_at, created_at)
OVERRIDING SYSTEM VALUE
SELECT id, user_id, kind, amount, expires_at, created_at
FROM ch07_r.src_txn ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch07_c.point_txns', 'id'),
              (SELECT max(id) FROM ch07_c.point_txns));

ANALYZE ch07_c.point_txns;

SELECT count(*) AS txns FROM ch07_c.point_txns;
