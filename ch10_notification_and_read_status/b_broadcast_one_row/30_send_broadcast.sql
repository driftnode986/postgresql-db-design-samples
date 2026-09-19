-- run-as: book_owner
--
-- 案B で全員向けの告知を 1 件送る。行は 1 つしか作らない。
-- 案A（a_row_per_recipient/30_send_broadcast.sql）とまったく同じ告知を送り、
-- かかった時間と書いた WAL を比べる。

\timing on
SET search_path TO ch10_b, public;

\echo '=== 送る前 ==='
SELECT count(*) AS rows_before FROM ch10_b.broadcasts;

SELECT pg_stat_force_next_flush();
SELECT wal_records, wal_bytes FROM pg_stat_wal \gset wal_before_

BEGIN;

\echo '=== 告知 1 件を全利用者に送る（1 行を足すだけ） ==='
INSERT INTO ch10_b.broadcasts (id, kind, body, created_at)
VALUES ((SELECT max(id) + 1 FROM ch10_b.broadcasts),
        'announcement', '臨時メンテナンスのお知らせ', now());

\echo '=== 送った直後の行数 ==='
SELECT count(*) AS rows_after FROM ch10_b.broadcasts;

ROLLBACK;

SELECT pg_stat_force_next_flush();

\echo '=== この操作が書いた WAL（操作 1 回あたり） ==='
SELECT wal_records - :wal_before_wal_records            AS wal_records,
       pg_size_pretty(wal_bytes - :wal_before_wal_bytes) AS wal_size
  FROM pg_stat_wal;
