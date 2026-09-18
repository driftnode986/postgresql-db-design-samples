-- 「ある日のある部屋の空き時間」を求める。
-- 範囲型を持つ案C では、営業時間の範囲から予約済みの範囲をまとめて引ける。
--
-- range_agg は複数の範囲を 1 つの multirange にまとめる集約関数。
-- multirange どうしの差（-）が、そのまま空き時間になる。

\timing on

-- 部屋 1 の 2026-01-02 の空き時間（営業時間は 9:00-18:00 とする）
EXPLAIN (ANALYZE)
SELECT tstzmultirange(tstzrange('2026-01-02 09:00+09','2026-01-02 18:00+09','[)'))
       - coalesce(range_agg(period), tstzmultirange()) AS free
FROM ch06_c.reservations
WHERE room_id = 1
  AND cancelled_at IS NULL
  AND period && tstzrange('2026-01-02 09:00+09','2026-01-02 18:00+09','[)');

-- 結果そのもの
SELECT tstzmultirange(tstzrange('2026-01-02 09:00+09','2026-01-02 18:00+09','[)'))
       - coalesce(range_agg(period), tstzmultirange()) AS free
FROM ch06_c.reservations
WHERE room_id = 1
  AND cancelled_at IS NULL
  AND period && tstzrange('2026-01-02 09:00+09','2026-01-02 18:00+09','[)');

-- 同じことを案B（2 列）で書くと、範囲を組み立て直すことになる
EXPLAIN (ANALYZE)
SELECT tstzmultirange(tstzrange('2026-01-02 09:00+09','2026-01-02 18:00+09','[)'))
       - coalesce(range_agg(tstzrange(start_at, end_at, '[)')), tstzmultirange()) AS free
FROM ch06_b.reservations
WHERE room_id = 1
  AND cancelled_at IS NULL
  AND start_at < timestamptz '2026-01-02 18:00+09'
  AND end_at   > timestamptz '2026-01-02 09:00+09';
