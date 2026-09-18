-- 元データを写す。開始・終了の 2 列を範囲型の 1 列にまとめる
SELECT count(*) AS src_rows FROM ch06_r.src_reservation \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch06_b.reservations, ch06_b.rooms RESTART IDENTITY CASCADE;

INSERT INTO ch06_b.rooms (id, name)
SELECT id, name FROM ch06_r.src_room ORDER BY id;

INSERT INTO ch06_b.reservations (id, room_id, user_id, period, cancelled_at)
OVERRIDING SYSTEM VALUE
SELECT id, room_id, user_id, tstzrange(start_at, end_at, '[)'), cancelled_at
FROM ch06_r.src_reservation ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch06_b.reservations', 'id'),
              (SELECT max(id) FROM ch06_b.reservations));

ANALYZE ch06_b.rooms, ch06_b.reservations;
