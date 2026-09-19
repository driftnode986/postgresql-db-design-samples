-- run-as: book_owner
--
-- 案A で全員向けの告知を 1 件送る。受信者の数だけ行を作る。
--
-- 🔴 BEGIN … ROLLBACK で囲む。確定させると、ほかの測定のサイズと行数が変わる
--    （第1章で、確定させた操作を 3 回繰り返して本体が 50 MB から 57 MB に増えた）。
--    WAL は ROLLBACK しても書かれるので、書き込み量の測定はこのままで正しい。

\timing on
SET search_path TO ch10_a, public;

\echo '=== 送る前 ==='
SELECT count(*) AS rows_before FROM ch10_a.notifications;

SELECT pg_stat_force_next_flush();
SELECT wal_records, wal_bytes FROM pg_stat_wal \gset wal_before_

BEGIN;

\echo '=== 告知 1 件を全利用者に送る（受信者ごとに 1 行） ==='
INSERT INTO ch10_a.notifications (user_id, kind, body, read_at, created_at)
SELECT u.id, 'announcement', '臨時メンテナンスのお知らせ', NULL, now()
  FROM ch10_r.src_user u;

\echo '=== 送った直後の行数 ==='
SELECT count(*) AS rows_after FROM ch10_a.notifications;

ROLLBACK;

SELECT pg_stat_force_next_flush();

\echo '=== この操作が書いた WAL（操作 1 回あたり） ==='
-- 🔴 1 行あたりに割り算しない。全ページ書き込みがチェックポイント直後に出るため、
--    1 行あたりの量として読むと誤る（docs/research/ch10_verification.md §12）。
SELECT wal_records - :wal_before_wal_records            AS wal_records,
       pg_size_pretty(wal_bytes - :wal_before_wal_bytes) AS wal_size
  FROM pg_stat_wal;
