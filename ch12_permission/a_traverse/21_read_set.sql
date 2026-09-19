-- run-as: book_app
-- 案A の書き方(2)「見える範囲を集合として作り、結合する」。
--
-- 設計（テーブルの形）は 20_read_func.sql とまったく同じである。変えたのは問い合わせの書き方だけ。
--
-- 🔴 UNION（UNION ALL ではない）を使う。所属が複数あると先祖が重複するため、
--    UNION ALL にすると同じ scope を何度もたどる。
--
-- 🔴 5 回繰り返して中央値と幅を取る（docs/measurement-rules.yml）。
\timing on

\echo '=== 利用者7 実行計画 3 回 ==='
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION
  SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION
  SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION
  SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 利用者7 素の実行 5 回（実行時間は下の Time: を読む） ==='
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 利用者42 実行計画 3 回 ==='
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 42
  UNION
  SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 42
  UNION
  SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 42
  UNION
  SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 利用者42 素の実行 5 回（実行時間は下の Time: を読む） ==='
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 42
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 42
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 42
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 42
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 42
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 🔴 2 つの書き方が同じ結果を返すこと（先頭列が 0 であること） ==='
-- 書き方を変えても結果が同じでなければ、速さを比べる意味がない。
-- 🔴 対称差は括弧で囲む（第9章の教訓）。
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id),
set_result AS (
  SELECT d.id FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id),
func_result AS (
  SELECT d.id FROM ch12_a.documents d WHERE ch12_a.can_view(7, d.id))
SELECT count(*) AS func_vs_set_diff_user7,
       (SELECT count(*) FROM set_result)  AS set_rows,
       (SELECT count(*) FROM func_result) AS func_rows
  FROM ((SELECT id FROM set_result  EXCEPT SELECT id FROM func_result)
        UNION ALL
        (SELECT id FROM func_result EXCEPT SELECT id FROM set_result)) t;
