-- 重なっている有効な予約の組（0 であること）
SELECT count(*) AS overlapping_pairs
FROM ch06_b.reservations AS a JOIN ch06_b.reservations AS b
  ON a.room_id = b.room_id AND a.id < b.id
 AND a.cancelled_at IS NULL AND b.cancelled_at IS NULL
 AND a.start_at < b.end_at AND a.end_at > b.start_at;
