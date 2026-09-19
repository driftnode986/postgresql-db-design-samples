-- run-as: book_app
-- 案A の書き方(3)「階層を ltree の経路で持ち、子孫の判定を 1 つの演算子で書く」。
--
-- 再帰 CTE をやめ、第4章の ltree を使う。scopes.path に 'n1.n2.n22' のような経路が
-- 入っているので、「所属した scope の子孫か」を `<@` で問える。
--
-- 🔴 companion は拡張を public に置き、run-sql.sh の search_path は「案のスキーマ, public」なので
--    型と演算子は見つかる。それでも **OPERATOR(public.<@) と public.ltree で修飾する**
--    （第4章の教訓。search_path が違う環境で黙って別の演算子に解決されるのを防ぐ）。
\timing on

\echo '=== 利用者7 実行計画 3 回 ==='
EXPLAIN (ANALYZE)
SELECT d.id, d.title
  FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m
                 JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 7
                  AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title
  FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m
                 JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 7
                  AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title
  FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m
                 JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 7
                  AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 利用者7 素の実行 5 回（実行時間は下の Time: を読む） ==='
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 7 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 7 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 7 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 7 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 7 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 利用者42 実行計画 3 回 ==='
EXPLAIN (ANALYZE)
SELECT d.id, d.title
  FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m
                 JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 42
                  AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title
  FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m
                 JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 42
                  AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title
  FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m
                 JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 42
                  AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 利用者42 素の実行 5 回（実行時間は下の Time: を読む） ==='
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 42 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 42 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 42 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 42 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
 WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                WHERE m.user_id = 42 AND p.path OPERATOR(public.<@) ms.path)
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 🔴 ltree 版が再帰 CTE 版と同じ結果を返すこと（先頭列が 0 であること） ==='
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id),
set_result AS (
  SELECT d.id FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id),
ltree_result AS (
  SELECT d.id FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
   WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m
                   JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                  WHERE m.user_id = 7 AND p.path OPERATOR(public.<@) ms.path))
SELECT count(*) AS set_vs_ltree_diff_user7,
       (SELECT count(*) FROM set_result)   AS set_rows,
       (SELECT count(*) FROM ltree_result) AS ltree_rows
  FROM ((SELECT id FROM set_result   EXCEPT SELECT id FROM ltree_result)
        UNION ALL
        (SELECT id FROM ltree_result EXCEPT SELECT id FROM set_result)) t;
