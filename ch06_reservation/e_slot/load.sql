-- 元データを写す。1 件の予約を、占める枠の行に展開する
SELECT count(*) AS src_rows FROM ch06_r.src_reservation \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch06_e.reservation_slots, ch06_e.reservations, ch06_e.rooms
  RESTART IDENTITY CASCADE;

INSERT INTO ch06_e.rooms (id, name)
SELECT id, name FROM ch06_r.src_room ORDER BY id;

INSERT INTO ch06_e.reservations (id, room_id, user_id, cancelled_at)
OVERRIDING SYSTEM VALUE
SELECT id, room_id, user_id, cancelled_at
FROM ch06_r.src_reservation ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch06_e.reservations', 'id'),
              (SELECT max(id) FROM ch06_e.reservations));

-- 🔴 キャンセル済みの予約は枠を占めない。枠の行を入れない形で表す
--    （一意制約に WHERE を付けられないため、案B の EXCLUDE ... WHERE と同じことを
--      「行を入れない」で実現している）
INSERT INTO ch06_e.reservation_slots (room_id, slot_start, reservation_id)
SELECT r.room_id, s.slot_start, r.id
FROM ch06_r.src_reservation AS r
CROSS JOIN LATERAL generate_series(r.start_at, r.end_at - interval '1 second',
                                   interval '1 hour') AS s(slot_start)
WHERE r.cancelled_at IS NULL
ORDER BY r.id, s.slot_start;

ANALYZE ch06_e.rooms, ch06_e.reservations, ch06_e.reservation_slots;
