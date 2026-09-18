-- run-as: book_owner
-- 排他制約のインデックスは「守る」ためのもので、「探す」ためのものではない。
--
-- 制約を作ると GiST のインデックスが付いてくるので、検索もそれで足りると考えたくなる。
-- ところが実測では、部屋を指定して空き時間を出す問い合わせがこのインデックスを使わない。
-- GiST での等価比較は B-tree ほど安くないため、案の実行計画が全体走査に倒れる。

\timing on

-- 1. 制約のインデックスしか無い状態
EXPLAIN (ANALYZE)
SELECT range_agg(period) FROM ch06_c.reservations
WHERE room_id = 1 AND cancelled_at IS NULL
  AND period && tstzrange('2026-01-02 09:00+09','2026-01-02 18:00+09','[)');

-- 2. 部屋を引くための B-tree を足す。有効な予約だけの部分インデックスにする
CREATE INDEX reservations_room_idx
  ON ch06_c.reservations (room_id) WHERE cancelled_at IS NULL;
ANALYZE ch06_c.reservations;

-- 3. 同じ問い合わせ。インデックス条件が room_id に変わる
EXPLAIN (ANALYZE)
SELECT range_agg(period) FROM ch06_c.reservations
WHERE room_id = 1 AND cancelled_at IS NULL
  AND period && tstzrange('2026-01-02 09:00+09','2026-01-02 18:00+09','[)');

-- 4. 足したインデックスの大きさ（守るためのインデックスに、探すためのインデックスを足す費用）
SELECT pg_size_pretty(pg_relation_size('ch06_c.reservations_room_idx')) AS search_index_size,
       pg_size_pretty(pg_relation_size('ch06_c.reservations_no_overlap')) AS constraint_index_size;

-- 後片付け（ほかの測定の条件を変えないように戻す）
DROP INDEX ch06_c.reservations_room_idx;
ANALYZE ch06_c.reservations;
