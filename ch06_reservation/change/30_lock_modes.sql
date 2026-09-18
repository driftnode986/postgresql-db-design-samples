-- run-as: book_owner
--
-- 移行の各段階で、どのロードを取るかを 1 つずつ確かめる。
--
-- 🔴 読み取りを止めるのは AccessExclusiveLock だけである。
--    行を埋める UPDATE は RowExclusiveLock なので、その間も読み書きは続けられる。
--    「移行のあいだテーブルが数秒止まる」と言えるのは、制約を足す段階についてである。
--    まとめて 1 つのトランザクションで測ると、最後にはすべてのロックが並ぶので
--    どの文がどれを取ったのかが分からなくなる。段階ごとに分けて測る。

-- 1. 行を埋める UPDATE（読み取りは止まらない）
BEGIN;
UPDATE ch06_a.reservations SET user_id = user_id WHERE id <= 100;
SELECT 'UPDATE' AS step, c.relname, l.mode
FROM pg_locks AS l JOIN pg_class AS c ON c.oid = l.relation
WHERE l.pid = pg_backend_pid() AND c.relname = 'reservations';
ROLLBACK;

-- 2. 列を足す（AccessExclusiveLock を取るが、18 では既定値があっても書き換えないので一瞬で終わる）
BEGIN;
ALTER TABLE ch06_a.reservations ADD COLUMN period_tmp tstzrange;
SELECT 'ADD COLUMN' AS step, c.relname, l.mode
FROM pg_locks AS l JOIN pg_class AS c ON c.oid = l.relation
WHERE l.pid = pg_backend_pid() AND c.relname = 'reservations';
ROLLBACK;

-- 3. 排他制約を足す（ここが読み取りを止める段階。既にある行をすべて調べるので時間がかかる）
BEGIN;
ALTER TABLE ch06_a.reservations
  ADD CONSTRAINT reservations_lock_demo EXCLUDE USING gist (
    room_id WITH =, tstzrange(start_at, end_at, '[)') WITH &&)
  WHERE (cancelled_at IS NULL);
SELECT 'ADD CONSTRAINT' AS step, c.relname, l.mode
FROM pg_locks AS l JOIN pg_class AS c ON c.oid = l.relation
WHERE l.pid = pg_backend_pid() AND c.relname = 'reservations';
ROLLBACK;
