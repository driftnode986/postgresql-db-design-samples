-- 重なっている予約の組（0 であること）。本体にはキャンセル済みが入らない
SELECT count(*) AS overlapping_pairs
FROM ch06_c.reservations AS a JOIN ch06_c.reservations AS b
  ON a.room_id = b.room_id AND a.reservation_no < b.reservation_no
 AND a.period && b.period;
