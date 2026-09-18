-- 変更の手数: 2 列で作った表（案B）を、範囲型の 1 列（案C）へ移す。
--
-- 🔴 BEGIN ... ROLLBACK で囲む。確定させるとサイズが変わり、以降の測定に効く
--    （消した列の定義は表に残り、繰り返すと本体が膨らむ）。
BEGIN;
\timing on

-- 移す前のファイルノード（表が書き換わったかを見る）
SELECT pg_relation_filenode('ch06_b.reservations') AS filenode_before \gset

-- 1. 範囲型の列を足す
ALTER TABLE ch06_b.reservations ADD COLUMN period tstzrange;

-- 2. 既にある行を埋める
UPDATE ch06_b.reservations SET period = tstzrange(start_at, end_at, '[)');

-- 3. NOT NULL にする
ALTER TABLE ch06_b.reservations ALTER COLUMN period SET NOT NULL;

-- 4. 新しい制約を足す（この時点では古い制約と二重に守られる）
ALTER TABLE ch06_b.reservations
  ADD CONSTRAINT reservations_no_overlap_range EXCLUDE USING gist (
    room_id WITH =, period WITH &&) WHERE (cancelled_at IS NULL);

-- 5. 古い制約と古い列を落とす
ALTER TABLE ch06_b.reservations DROP CONSTRAINT reservations_no_overlap;
ALTER TABLE ch06_b.reservations DROP COLUMN start_at, DROP COLUMN end_at;

-- 表が書き換わったか（filenode が変わっていれば書き換え）
SELECT :'filenode_before' AS filenode_before,
       pg_relation_filenode('ch06_b.reservations') AS filenode_after,
       :'filenode_before' = pg_relation_filenode('ch06_b.reservations')::text AS unchanged;

-- この変更で取ったロック
SELECT c.relname, l.mode
FROM pg_locks AS l JOIN pg_class AS c ON c.oid = l.relation
WHERE l.pid = pg_backend_pid() AND c.relname LIKE 'reservations%'
ORDER BY c.relname, l.mode;

ROLLBACK;
