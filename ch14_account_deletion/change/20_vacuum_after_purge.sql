-- run-as: book_owner
-- standalone
--
-- 大量の物理削除のあと、テーブルはいつ小さくなるか。
-- 🔴 この測定はデータを壊すので、ほかの測定より後に置く。
CREATE SCHEMA IF NOT EXISTS ch14_z;
DROP TABLE IF EXISTS ch14_z.vac;

CREATE TABLE ch14_z.vac (id bigint PRIMARY KEY, pad text);
INSERT INTO ch14_z.vac
SELECT i, repeat('x', 200) FROM generate_series(1, 200000) i;
VACUUM ANALYZE ch14_z.vac;

SELECT pg_size_pretty(pg_total_relation_size('ch14_z.vac')) AS size_before_delete;

-- 90% を消す
DELETE FROM ch14_z.vac WHERE id % 10 <> 0;

SELECT pg_size_pretty(pg_total_relation_size('ch14_z.vac')) AS size_after_delete;

VACUUM ch14_z.vac;
SELECT pg_size_pretty(pg_total_relation_size('ch14_z.vac')) AS size_after_vacuum;

-- 🔴 VACUUM FULL は AccessExclusiveLock を取る（読み書きが止まる）
VACUUM FULL ch14_z.vac;
SELECT pg_size_pretty(pg_total_relation_size('ch14_z.vac')) AS size_after_vacuum_full;
