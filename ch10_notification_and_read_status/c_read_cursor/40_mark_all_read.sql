-- run-as: book_owner
--
-- 案C で「すべて既読にする」。
-- 告知の側はカーソルを 1 行更新するだけで終わる。
-- 個別の通知は案A と同じく行を書き換える（カーソルは告知にしか効かない）。
--
-- 🔴 案A と比べるときは、比べている対象をそろえること。
--    「案C なら 1 行で済む」のは**告知の既読**であって、個別の通知ではない。
--    ここを混ぜると、案C を過大評価する。

\timing on
SET search_path TO ch10_c, public;

\echo '=== 更新する前 ==='
SELECT (SELECT broadcast_read_upto FROM ch10_c.read_cursors WHERE user_id = 107)
         AS cursor_before,
       (SELECT max(id) FROM ch10_c.broadcasts) AS latest_broadcast,
       (SELECT count(*) FROM ch10_c.broadcasts b
         WHERE b.id > (SELECT broadcast_read_upto FROM ch10_c.read_cursors
                        WHERE user_id = 107)) AS unread_broadcasts;

SELECT pg_stat_force_next_flush();
SELECT wal_records, wal_bytes FROM pg_stat_wal \gset wal_before_

BEGIN;

\echo '=== 告知をすべて既読にする（カーソルを 1 行更新） ==='
UPDATE ch10_c.read_cursors
   SET broadcast_read_upto = (SELECT max(id) FROM ch10_c.broadcasts),
       updated_at = now()
 WHERE user_id = 107;

ROLLBACK;

SELECT pg_stat_force_next_flush();

\echo '=== この操作が書いた WAL（操作 1 回あたり） ==='
SELECT wal_records - :wal_before_wal_records            AS wal_records,
       pg_size_pretty(wal_bytes - :wal_before_wal_bytes) AS wal_size
  FROM pg_stat_wal;
