-- 重なっている有効な予約の組（0 であること）。範囲型なので && で書ける
SELECT count(*) AS overlapping_pairs
FROM ch06_c.reservations AS a JOIN ch06_c.reservations AS b
  ON a.room_id = b.room_id AND a.id < b.id
 AND a.cancelled_at IS NULL AND b.cancelled_at IS NULL
 AND a.period && b.period;
-- 空の範囲が入っていないこと（CHECK が効いているかの確認）
SELECT count(*) AS empty_periods FROM ch06_c.reservations WHERE isempty(period);
