-- 未読件数と未読 20 件。ヘッダーに常に表示されるので、最も頻度が高い問い合わせ。
--
-- 🔴 検算の入口: 採取した案のうち opus だけが
--    「3 億件を数えるクエリは絶対に間に合わない」と断定し、
--    カウンタ列を持つ設計を出した（docs/research/ch10_first_idea.md）。
--    ほかの 2 本は素直に count(*) で数えている。
--    **その断定が正しいかを、部分インデックスを張った状態で測る。**
--
-- 🔴 測る対象は「ためこむ人」（user_id % 100 = 7）にする。
--    未読が均等に散った利用者を選ぶと未読 0 件になり、案の差が測れない
--    （docs/research/ch10_verification.md §17）。
--
-- このファイルは案ごとの search_path で実行される（どの案にも notifications がある）。

\timing on

\echo '=== 対象の利用者の未読件数（個別の通知） ==='
SELECT user_id, count(*) AS unread
  FROM notifications
 WHERE user_id = 107 AND read_at IS NULL
 GROUP BY user_id;

\echo '=== (1) 未読件数を数える（3 回） ==='
EXPLAIN (ANALYZE) SELECT count(*) FROM notifications
 WHERE user_id = 107 AND read_at IS NULL;
EXPLAIN (ANALYZE) SELECT count(*) FROM notifications
 WHERE user_id = 107 AND read_at IS NULL;
EXPLAIN (ANALYZE) SELECT count(*) FROM notifications
 WHERE user_id = 107 AND read_at IS NULL;

\echo '=== (2) 未読を新しい順に 20 件（3 回） ==='
EXPLAIN (ANALYZE) SELECT id, kind, body, created_at FROM notifications
 WHERE user_id = 107 AND read_at IS NULL ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, kind, body, created_at FROM notifications
 WHERE user_id = 107 AND read_at IS NULL ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, kind, body, created_at FROM notifications
 WHERE user_id = 107 AND read_at IS NULL ORDER BY created_at DESC LIMIT 20;
