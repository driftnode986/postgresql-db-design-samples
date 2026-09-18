-- 元データを写し、そのあとで締め残高を作る
SELECT count(*) AS src_rows FROM ch07_r.src_txn \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch07_d.point_snapshots, ch07_d.point_txns RESTART IDENTITY CASCADE;

INSERT INTO ch07_d.point_txns (id, user_id, kind, amount, expires_at, created_at)
OVERRIDING SYSTEM VALUE
SELECT id, user_id, kind, amount, expires_at, created_at
FROM ch07_r.src_txn ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch07_d.point_txns', 'id'),
              (SELECT max(id) FROM ch07_d.point_txns));

-- 締め。会員ごとに「最後から 100 件手前」で締めたことにする。
-- 🔴 締めの位置は運用で決まる（月次など）。ここでは案C との差が読めるように、
--    締めのあとに残る取引の件数を会員によらずそろえた
INSERT INTO ch07_d.point_snapshots (user_id, as_of_txn_id, balance)
SELECT user_id, cut,
       coalesce(sum(CASE WHEN kind = 'grant' THEN amount ELSE -amount END)
                FILTER (WHERE id <= cut), 0)
FROM (
  SELECT t.*,
         coalesce((SELECT id FROM ch07_d.point_txns AS u
                   WHERE u.user_id = t.user_id ORDER BY u.id DESC
                   OFFSET 100 LIMIT 1), 0) AS cut
  FROM ch07_d.point_txns AS t
) AS x
GROUP BY user_id, cut
HAVING cut > 0;

ANALYZE ch07_d.point_txns, ch07_d.point_snapshots;

SELECT count(*) AS snapshots FROM ch07_d.point_snapshots;
