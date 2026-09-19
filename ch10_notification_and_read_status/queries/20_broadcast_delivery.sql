-- 全員向けの告知を 1 件送るコスト。
--
-- 案A は利用者の数だけ行を作る。案B・案C は 1 行で済む。
-- この差が、案A と案B を分ける最大の理由である。
--
-- 🔴 このファイルは案ごとの search_path で実行される。
--    案A には broadcasts が無く、案B・案C には notifications への展開が無いので、
--    それぞれの案で「告知 1 件を送る」形を書き分ける必要がある。
--    共通で測れるのは「送ったあとに増えた行数とサイズ」なので、
--    送る操作そのものは案のディレクトリ側（30_send_broadcast.sql）に置く。
--
-- ここでは送る前の状態だけを記録する。
--
-- 🔴 元データのスキーマ（ch10_r）には notifications が無い。
--    検査は queries/ の全ファイルを全スキーマに対して流すので、
--    表が無いときは何もせずに終わるようにしておく。
SELECT NOT EXISTS (
  SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE c.relname = 'notifications' AND c.relkind = 'r'
     AND n.nspname = split_part(current_setting('search_path'), ',', 1)
) AS skip \gset
\if :skip
  \echo '(このスキーマには notifications が無いので測らない)'
  \quit
\endif

\timing on

\echo '=== 送る前の行数 ==='
SELECT count(*) AS notification_rows FROM notifications;

\echo '=== 送る前のサイズ ==='
SELECT pg_size_pretty(pg_relation_size('notifications'))       AS heap,
       pg_size_pretty(pg_indexes_size('notifications'))        AS indexes,
       pg_size_pretty(pg_total_relation_size('notifications')) AS total;
