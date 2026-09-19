-- run-as: book_app
-- 案B の一覧。案A の集合方式（a_traverse/21_read_set.sql）と比べる。
--
-- 🔴 この測定の目的は「案B が一覧を速くするか」を確かめることである。
--    所属をたどる部分は案A と同じで、案B が足したのは
--    role_permissions への結合（「読む権限を持つ役割での所属か」）だけである。
--    それが一覧の時間を変えるのか、変えないのかを見る。
\timing on

\echo '=== 案B 利用者7 実行計画 3 回（読む権限を持つ役割での所属だけを集合にする） ==='
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id
    FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 7 AND p.code = 'document.read'
  UNION
  SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id
    FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 7 AND p.code = 'document.read'
  UNION
  SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id
    FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 7 AND p.code = 'document.read'
  UNION
  SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 案B 利用者7 素の実行 5 回（実行時間は下の Time: を読む） ==='
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 7 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 7 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 7 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 7 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 7 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 案B 利用者42 素の実行 5 回（実行時間は下の Time: を読む） ==='
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 42 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 42 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 42 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 42 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 42 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id, d.title FROM ch12_b.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 🔴 案B が案A と同じ一覧を返すこと（先頭列が 0 であること） ==='
-- 返す文書が違えば、時間を比べる意味がない。
WITH RECURSIVE vis_a AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis_a ON s.parent_id = vis_a.id),
a AS (SELECT d.id FROM ch12_a.documents d JOIN vis_a ON vis_a.id = d.project_id),
vis_b AS (
  SELECT m.scope_id AS id FROM ch12_b.memberships m
    JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
    JOIN ch12_b.permissions p ON p.id = rp.permission_id
   WHERE m.user_id = 7 AND p.code = 'document.read'
  UNION SELECT s.id FROM ch12_b.scopes s JOIN vis_b ON s.parent_id = vis_b.id),
b AS (SELECT d.id FROM ch12_b.documents d JOIN vis_b ON vis_b.id = d.project_id)
SELECT count(*) AS a_vs_b_diff_user7,
       (SELECT count(*) FROM a) AS a_rows,
       (SELECT count(*) FROM b) AS b_rows
  FROM ((SELECT id FROM a EXCEPT SELECT id FROM b)
        UNION ALL
        (SELECT id FROM b EXCEPT SELECT id FROM a)) t;

\echo '=== 🔴 案B にしかできない問い: この人はこの操作をできるか ==='
-- 案A はここで「所属の role という文字列をアプリ側で解釈する」しかない。
-- 案B は表に答えがある。
--
-- 利用者7 は project 22 の閲覧者ではないが、自分が editor で所属するプロジェクトでは書ける。
SELECT m.scope_id,
       ch12_b.can(7, m.scope_id, 'document.read')  AS can_read,
       ch12_b.can(7, m.scope_id, 'document.write') AS can_write,
       ch12_b.can(7, m.scope_id, 'member.invite')  AS can_invite
  FROM ch12_b.memberships m WHERE m.user_id = 7 ORDER BY m.scope_id;

\echo '=== 案B の関数の実行計画（1 件の判定。一覧ではない） ==='
EXPLAIN (ANALYZE)
SELECT ch12_b.can(7, 25, 'document.write');
