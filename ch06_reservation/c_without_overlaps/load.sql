-- 元データを写す。
-- 🔴 この案はキャンセル済みを判定から外せないので、有効な予約だけを本体に入れ、
--    キャンセル済みは cancelled_reservations へ分けて入れる
SELECT count(*) AS src_rows FROM ch06_r.src_reservation \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch06_c.reservations, ch06_c.cancelled_reservations, ch06_c.rooms
  RESTART IDENTITY CASCADE;

INSERT INTO ch06_c.rooms (id, name)
SELECT id, name FROM ch06_r.src_room ORDER BY id;

INSERT INTO ch06_c.reservations (room_id, period, user_id, reservation_no)
OVERRIDING SYSTEM VALUE
SELECT room_id, tstzrange(start_at, end_at, '[)'), user_id, id
FROM ch06_r.src_reservation WHERE cancelled_at IS NULL ORDER BY id;

INSERT INTO ch06_c.cancelled_reservations
       (reservation_no, room_id, period, user_id, cancelled_at)
SELECT id, room_id, tstzrange(start_at, end_at, '[)'), user_id, cancelled_at
FROM ch06_r.src_reservation WHERE cancelled_at IS NOT NULL ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch06_c.reservations', 'reservation_no'),
              (SELECT max(reservation_no) FROM ch06_c.reservations));

ANALYZE ch06_c.rooms, ch06_c.reservations, ch06_c.cancelled_reservations;
