-- 元データを写す。測定のたびに入れ直す
SELECT count(*) AS src_rows FROM ch06_r.src_reservation \gset
SELECT CASE WHEN :src_rows = 0
            THEN 1/0 ELSE 1 END AS source_must_not_be_empty;  -- 空なら何も消さずに止まる

\timing on
TRUNCATE ch06_f.reservations, ch06_f.rooms RESTART IDENTITY CASCADE;

INSERT INTO ch06_f.rooms (id, name)
SELECT id, name FROM ch06_r.src_room ORDER BY id;

INSERT INTO ch06_f.reservations (id, room_id, user_id, start_at, end_at, cancelled_at)
OVERRIDING SYSTEM VALUE
SELECT id, room_id, user_id, start_at, end_at, cancelled_at
FROM ch06_r.src_reservation ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch06_f.reservations', 'id'),
              (SELECT max(id) FROM ch06_f.reservations));

ANALYZE ch06_f.rooms, ch06_f.reservations;
