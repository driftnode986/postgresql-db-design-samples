-- 1 つの枠を 2 件の有効な予約が占めていないこと（0 であること）。
-- 一意制約があるので構造上起きないが、キャンセルの扱いを間違えると起きうる
SELECT count(*) AS double_booked_slots FROM (
  SELECT s.room_id, s.slot_start
  FROM ch06_d.reservation_slots AS s
  JOIN ch06_d.reservations AS r ON r.id = s.reservation_id
  WHERE r.cancelled_at IS NULL
  GROUP BY s.room_id, s.slot_start HAVING count(*) > 1) AS d;
-- キャンセル済みの予約が枠を占めていないこと（0 であること）
SELECT count(*) AS cancelled_holding_slots
FROM ch06_d.reservation_slots AS s
JOIN ch06_d.reservations AS r ON r.id = s.reservation_id
WHERE r.cancelled_at IS NOT NULL;
