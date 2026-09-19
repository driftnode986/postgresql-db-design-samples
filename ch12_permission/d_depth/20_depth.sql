-- run-as: book_app
-- 深さを 2・4・6・8・10・12 と変えて、案A（再帰 CTE）の一覧を測る。
--
-- 🔴 深さの上限を `s.lvl < :d` で切る。データは 1 つで、たどる段数だけを変える。
--    こうすると文書の数・所属の数・キャッシュの温まり方が揃うので、
--    差が出たらそれは深さの差である。
--
-- 🔴 確認記録（§8）は 1 深さにつき 1 回しか測っておらず、幅を出していなかった。
--    ここでは **各深さ 5 回**取る。幅（(最大−最小)/中央値）より小さい差は主張しない
--    （docs/measurement-rules.yml の claims）。
--
-- 🔴 深さを切ると、その深さで届かない文書は一覧に出ない。
--    出る件数も一緒に記録する（0 件のものを速いと言わないため）。
\timing on

\echo '=== 各深さの実行計画（1 回ずつ。Recursive Union の行数を見る） ==='
\echo '--- depth <= 2 ---'
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 2)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '--- depth <= 4 ---'
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 4)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '--- depth <= 6 ---'
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 6)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '--- depth <= 8 ---'
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 8)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '--- depth <= 10 ---'
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 10)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '--- depth <= 12 ---'
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 12)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 各深さ 5 回ずつ（実行時間は下の Time: を読む） ==='
\echo '--- depth <= 2 を 5 回 ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 2)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 2)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 2)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 2)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 2)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '--- depth <= 4 を 5 回 ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 4)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 4)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 4)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 4)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 4)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '--- depth <= 6 を 5 回 ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 6)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 6)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 6)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 6)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 6)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '--- depth <= 8 を 5 回 ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 8)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 8)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 8)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 8)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 8)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '--- depth <= 10 を 5 回 ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 10)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 10)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 10)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 10)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 10)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '--- depth <= 12 を 5 回 ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 12)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 12)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 12)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 12)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 12)
SELECT d.id, d.title FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 各深さで一覧に出る文書の数と、たどった節点の数 ==='
\echo '--- depth <= 2 で一覧に出る文書の総数（0 件でないことの確認） ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 2)
SELECT 2 AS depth_limit,
       (SELECT count(*) FROM vis) AS scopes_traversed,
       count(*)                   AS visible_documents
  FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id;

\echo '--- depth <= 4 で一覧に出る文書の総数（0 件でないことの確認） ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 4)
SELECT 4 AS depth_limit,
       (SELECT count(*) FROM vis) AS scopes_traversed,
       count(*)                   AS visible_documents
  FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id;

\echo '--- depth <= 6 で一覧に出る文書の総数（0 件でないことの確認） ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 6)
SELECT 6 AS depth_limit,
       (SELECT count(*) FROM vis) AS scopes_traversed,
       count(*)                   AS visible_documents
  FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id;

\echo '--- depth <= 8 で一覧に出る文書の総数（0 件でないことの確認） ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 8)
SELECT 8 AS depth_limit,
       (SELECT count(*) FROM vis) AS scopes_traversed,
       count(*)                   AS visible_documents
  FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id;

\echo '--- depth <= 10 で一覧に出る文書の総数（0 件でないことの確認） ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 10)
SELECT 10 AS depth_limit,
       (SELECT count(*) FROM vis) AS scopes_traversed,
       count(*)                   AS visible_documents
  FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id;

\echo '--- depth <= 12 で一覧に出る文書の総数（0 件でないことの確認） ---'
WITH RECURSIVE vis AS (
  SELECT s.id, s.lvl FROM ch12_d.scopes s
   WHERE s.id IN (SELECT m.scope_id FROM ch12_d.memberships m WHERE m.user_id = 1)
  UNION
  SELECT s.id, s.lvl FROM ch12_d.scopes s JOIN vis ON s.parent_id = vis.id
   WHERE vis.lvl < 12)
SELECT 12 AS depth_limit,
       (SELECT count(*) FROM vis) AS scopes_traversed,
       count(*)                   AS visible_documents
  FROM ch12_d.documents d JOIN vis ON vis.id = d.project_id;

