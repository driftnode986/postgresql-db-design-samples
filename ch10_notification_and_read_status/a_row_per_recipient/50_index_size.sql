-- run-as: book_owner
--
-- 部分インデックスと全行インデックスのサイズを比べる。
--
-- 🔴 比べるのは「同じ問い合わせを成立させる索引どうし」にする。
--    列数の違うものを並べると倍率が水増しされる。
--    企画は「128 kB 対 9,264 kB ＝ 約 70 倍」と書いていたが、
--    これは 1 列の部分索引と INCLUDE 付きの全行索引を比べていた誤りで、
--    そろえると約 20 倍になる（docs/research/ch10_research.md §1-1）。
--
-- どちらも (user_id, created_at DESC) で、
-- 「未読を新しい順に 20 件」を索引の順序のまま返せる形にそろえる。

\timing on
SET search_path TO ch10_a, public;

-- 全行の索引を、比較のためだけに作る
CREATE INDEX IF NOT EXISTS notif_a_all
  ON ch10_a.notifications (user_id, created_at DESC);

ANALYZE ch10_a.notifications;

\echo '=== 同じ問い合わせを支える 2 つの索引のサイズ ==='
SELECT 'notif_a_unread（WHERE read_at IS NULL）' AS idx,
       pg_size_pretty(pg_relation_size('ch10_a.notif_a_unread')) AS size,
       pg_relation_size('ch10_a.notif_a_unread') AS bytes
UNION ALL
SELECT 'notif_a_all（全行）',
       pg_size_pretty(pg_relation_size('ch10_a.notif_a_all')),
       pg_relation_size('ch10_a.notif_a_all')
ORDER BY bytes;

\echo '=== 倍率と、未読率 ==='
SELECT round(pg_relation_size('ch10_a.notif_a_all')::numeric
             / pg_relation_size('ch10_a.notif_a_unread'), 1) AS size_ratio,
       count(*) AS rows,
       count(*) FILTER (WHERE read_at IS NULL) AS unread,
       round(100.0 * count(*) FILTER (WHERE read_at IS NULL) / count(*), 2)
         AS unread_pct
  FROM ch10_a.notifications;

\echo '=== 表の全体（本体・索引・合計） ==='
SELECT pg_size_pretty(pg_relation_size('ch10_a.notifications'))       AS heap,
       pg_size_pretty(pg_indexes_size('ch10_a.notifications'))        AS indexes,
       pg_size_pretty(pg_total_relation_size('ch10_a.notifications')) AS total;

\echo '=== 全行の索引しか無いときの実行計画（比較用） ==='
-- 🔴 BEGIN … ROLLBACK で囲み、部分索引を落とした状態を確定させない。
--    確定させると、あとの測定が索引の無い状態で走る。
BEGIN;
DROP INDEX ch10_a.notif_a_unread;
EXPLAIN (ANALYZE) SELECT id, kind, body, created_at FROM ch10_a.notifications
 WHERE user_id = 107 AND read_at IS NULL ORDER BY created_at DESC LIMIT 20;
ROLLBACK;

\echo '=== 比較のために作った全行の索引を落とす ==='
DROP INDEX ch10_a.notif_a_all;
