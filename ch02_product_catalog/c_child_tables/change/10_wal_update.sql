-- 属性を 1 つだけ更新したときに書かれる WAL（変更の記録）の量。衣料の先頭 1,000 商品の素材を変える。
-- 同じ更新を 2 回行い、2 回目を見る。1 回目は、チェックポイントの後で初めて変更するページの全体を
-- WAL に書く（wal_fpi）ので、その分が上乗せされる
SELECT pg_stat_force_next_flush();
SELECT pg_current_wal_insert_lsn() AS lsn0, wal_records AS rec0, wal_fpi AS fpi0
FROM pg_stat_wal \gset

UPDATE apparel SET material = 'wool' WHERE product_id IN (
  SELECT product_id FROM apparel ORDER BY product_id LIMIT 1000);

SELECT pg_stat_force_next_flush();
SELECT pg_current_wal_insert_lsn() AS lsn1, wal_records AS rec1, wal_fpi AS fpi1
FROM pg_stat_wal \gset

UPDATE apparel SET material = 'linen' WHERE product_id IN (
  SELECT product_id FROM apparel ORDER BY product_id LIMIT 1000);

SELECT pg_stat_force_next_flush();
SELECT pg_wal_lsn_diff(:'lsn1', :'lsn0') AS first_bytes,
       :rec1 - :rec0 AS first_records, :fpi1 - :fpi0 AS first_fpi,
       pg_wal_lsn_diff(pg_current_wal_insert_lsn(), :'lsn1') AS second_bytes,
       wal_records - :rec1 AS second_records, wal_fpi - :fpi1 AS second_fpi
FROM pg_stat_wal;
