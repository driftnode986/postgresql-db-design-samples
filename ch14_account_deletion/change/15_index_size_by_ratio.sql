-- run-as: book_owner
-- standalone
-- 削除済みの割合ごとに、全体インデックスと部分インデックスのサイズを比べる。
--
-- 🔴 案A の users そのものは触らない（ほかの測定に影響するため）。
--    別のスキーマに同じ形の表を作って測る。
--
-- 🔴 割合は毎回「絶対値で置き直す」。前の状態に UPDATE を重ねると、
--    50% のあとに「id % 10 <> 0」を足して 95%、さらに重ねて 100% になり、
--    部分インデックスが空（8 kB）になったまま「90% の値」として読める。
--    実際に一度そうなった。各段で割合そのものを測って記録する。
CREATE SCHEMA IF NOT EXISTS ch14_z;
DROP TABLE IF EXISTS ch14_z.ratio;

CREATE TABLE ch14_z.ratio (
  id bigint PRIMARY KEY, email text NOT NULL, deleted_at timestamptz
);
INSERT INTO ch14_z.ratio SELECT i, 'u' || i || '@example.com', NULL
FROM generate_series(1, 200000) i;
CREATE INDEX ratio_all  ON ch14_z.ratio (email);
CREATE INDEX ratio_part ON ch14_z.ratio (email) WHERE deleted_at IS NULL;

-- 割合 0%
UPDATE ch14_z.ratio SET deleted_at = NULL;
REINDEX TABLE ch14_z.ratio;
ANALYZE ch14_z.ratio;
SELECT '削除済み 0%' AS label,
       round(100.0 * count(*) FILTER (WHERE deleted_at IS NOT NULL) / count(*), 1)
         AS measured_pct,
       pg_relation_size('ch14_z.ratio_all')  AS idx_all_bytes,
       pg_relation_size('ch14_z.ratio_part') AS idx_partial_bytes
FROM ch14_z.ratio;

-- 割合 50%（絶対値で置き直す）
UPDATE ch14_z.ratio SET deleted_at = CASE WHEN id % 2 = 0 THEN now() END;
REINDEX TABLE ch14_z.ratio;
ANALYZE ch14_z.ratio;
SELECT '削除済み 50%' AS label,
       round(100.0 * count(*) FILTER (WHERE deleted_at IS NOT NULL) / count(*), 1)
         AS measured_pct,
       pg_relation_size('ch14_z.ratio_all')  AS idx_all_bytes,
       pg_relation_size('ch14_z.ratio_part') AS idx_partial_bytes
FROM ch14_z.ratio;

-- 割合 90%（絶対値で置き直す）
UPDATE ch14_z.ratio SET deleted_at = CASE WHEN id % 10 <> 0 THEN now() END;
REINDEX TABLE ch14_z.ratio;
ANALYZE ch14_z.ratio;
SELECT '削除済み 90%' AS label,
       round(100.0 * count(*) FILTER (WHERE deleted_at IS NOT NULL) / count(*), 1)
         AS measured_pct,
       pg_relation_size('ch14_z.ratio_all')  AS idx_all_bytes,
       pg_relation_size('ch14_z.ratio_part') AS idx_partial_bytes
FROM ch14_z.ratio;

-- 🔴 検査: 最後の段で「残っている行」が 0 でないこと。
--    0 だと部分インデックスが空になり、サイズの比較が意味を失う（先頭列 0）。
SELECT CASE WHEN count(*) FILTER (WHERE deleted_at IS NULL) > 0 THEN 0 ELSE 1 END
         AS active_rows_must_remain
FROM ch14_z.ratio;
