-- run-as: book_owner
--
-- 案A で「すべて既読にする」。未読の行をすべて書き換える。
--
-- 🔴 対象は「ためこむ人」（user_id = 107）にする。未読が 0 件の利用者を選ぶと
--    0 行の UPDATE になり、案の差が測れない（§17）。

\timing on
SET search_path TO ch10_a, public;

\echo '=== 更新する前の未読件数 ==='
SELECT count(*) AS unread_before FROM ch10_a.notifications
 WHERE user_id = 107 AND read_at IS NULL;

SELECT pg_stat_force_next_flush();
SELECT wal_records, wal_bytes FROM pg_stat_wal \gset wal_before_

BEGIN;

\echo '=== すべて既読にする ==='
UPDATE ch10_a.notifications SET read_at = now()
 WHERE user_id = 107 AND read_at IS NULL;

ROLLBACK;

SELECT pg_stat_force_next_flush();

\echo '=== この操作が書いた WAL（操作 1 回あたり） ==='
SELECT wal_records - :wal_before_wal_records            AS wal_records,
       pg_size_pretty(wal_bytes - :wal_before_wal_bytes) AS wal_size
  FROM pg_stat_wal;

-- 🔴 ここからが案C と比べるための測定である。
--    上の UPDATE は個別の通知と告知の両方を既読にしている。
--    案C のカーソルが引き受けるのは**告知だけ**なので、
--    そのまま案C の「1 行」と比べると案C を過大評価する。
--    比べる対象をそろえて、告知だけを既読にする場合を測る。

\echo '=== 未読の内訳（個別の通知と告知） ==='
SELECT count(*) FILTER (WHERE kind =  'announcement') AS unread_announcements,
       count(*) FILTER (WHERE kind <> 'announcement') AS unread_personal
  FROM ch10_a.notifications
 WHERE user_id = 107 AND read_at IS NULL;

SELECT pg_stat_force_next_flush();
SELECT wal_records, wal_bytes FROM pg_stat_wal \gset wal_bc_

BEGIN;

\echo '=== 告知だけを既読にする（案C と比べる対象） ==='
UPDATE ch10_a.notifications SET read_at = now()
 WHERE user_id = 107 AND kind = 'announcement' AND read_at IS NULL;

ROLLBACK;

SELECT pg_stat_force_next_flush();

\echo '=== 告知だけを既読にしたときの WAL ==='
SELECT wal_records - :wal_bc_wal_records            AS wal_records,
       pg_size_pretty(wal_bytes - :wal_bc_wal_bytes) AS wal_size
  FROM pg_stat_wal;
