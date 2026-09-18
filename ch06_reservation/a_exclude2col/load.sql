-- 元データを写す
SELECT count(*) AS src_rows FROM ch06_r.src_reservation \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch06_a.reservations, ch06_a.rooms RESTART IDENTITY CASCADE;

INSERT INTO ch06_a.rooms (id, name)
SELECT id, name FROM ch06_r.src_room ORDER BY id;

INSERT INTO ch06_a.reservations (id, room_id, user_id, start_at, end_at, cancelled_at)
OVERRIDING SYSTEM VALUE
SELECT id, room_id, user_id, start_at, end_at, cancelled_at
FROM ch06_r.src_reservation ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch06_a.reservations', 'id'),
              (SELECT max(id) FROM ch06_a.reservations));

ANALYZE ch06_a.rooms, ch06_a.reservations;
