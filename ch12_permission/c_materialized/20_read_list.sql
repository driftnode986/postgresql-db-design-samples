-- run-as: book_app
-- 案C の一覧。階層をたどらず、判定表を user_id で引いて新しい順に 20 件。
--
-- 🔴 企画の仮説は「実体化すれば速くなる」だった。それを確かめる。
--    速いのは「たどらない」ぶんだが、引く表が元データより 2 桁大きいので、
--    索引を読む量は増える。どちらが勝つかを測る。
\timing on

\echo '=== 案C 利用者7 実行計画 3 回 ==='
EXPLAIN (ANALYZE)
SELECT ea.document_id, d.title
  FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 7
 ORDER BY ea.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT ea.document_id, d.title
  FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 7
 ORDER BY ea.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT ea.document_id, d.title
  FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 7
 ORDER BY ea.created_at DESC LIMIT 20;

\echo '=== 案C 利用者7 素の実行 5 回（実行時間は下の Time: を読む） ==='
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 7 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 7 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 7 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 7 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 7 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 案C 利用者42 実行計画 3 回 ==='
EXPLAIN (ANALYZE)
SELECT ea.document_id, d.title
  FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 42
 ORDER BY ea.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT ea.document_id, d.title
  FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 42
 ORDER BY ea.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT ea.document_id, d.title
  FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 42
 ORDER BY ea.created_at DESC LIMIT 20;

\echo '=== 案C 利用者42 素の実行 5 回（実行時間は下の Time: を読む） ==='
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 42 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 42 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 42 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 42 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null
SELECT ea.document_id, d.title FROM ch12_c.effective_access ea
  JOIN ch12_c.documents d ON d.id = ea.document_id
 WHERE ea.user_id = 42 ORDER BY ea.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 🔴 案C が案A と同じ一覧を返すこと（先頭列が 0 であること） ==='
WITH RECURSIVE vis_a AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis_a ON s.parent_id = vis_a.id),
a AS (SELECT d.id FROM ch12_a.documents d JOIN vis_a ON vis_a.id = d.project_id),
c AS (SELECT ea.document_id AS id FROM ch12_c.effective_access ea WHERE ea.user_id = 7)
SELECT count(*) AS a_vs_c_diff_user7,
       (SELECT count(*) FROM a) AS a_rows,
       (SELECT count(*) FROM c) AS c_rows
  FROM ((SELECT id FROM a EXCEPT SELECT id FROM c)
        UNION ALL
        (SELECT id FROM c EXCEPT SELECT id FROM a)) t;
