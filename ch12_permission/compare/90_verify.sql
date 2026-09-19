-- run-as: book_owner
-- 3 案（と 4 つの書き方）が、同じ利用者に同じ文書を返すことを確かめる。比較の前提である。
--
-- 🔴 返す全行の先頭列が 0 になるように書く（検証スクリプトが 0 でない行を FAIL にする）。
-- 🔴 「差が 0」だけでは正しさの証明にならない（第8章 C1）。
--    同じ誤りを両側に含んだ比較はいつでも 0 を返すので、
--    **比べる対象が空でないこと**を必ず同時に検査する。
-- 🔴 対称差は必ず括弧で囲む（第9章の教訓）。

\echo '=== (0) 比べる対象が空でないこと（先頭列が 0 であること） ==='
SELECT (SELECT count(*) FROM ch12_r.src_document)      = 0 AS source_empty,
       (SELECT count(*) FROM ch12_a.documents)         = 0 AS a_empty,
       (SELECT count(*) FROM ch12_b.documents)         = 0 AS b_empty,
       (SELECT count(*) FROM ch12_c.documents)         = 0 AS c_empty,
       (SELECT count(*) FROM ch12_c.effective_access)  = 0 AS c_access_empty;

\echo '=== (1) 利用者7 の「見える文書」が 4 通りで一致すること ==='
-- 案A 関数 / 案A 集合 / 案A ltree / 案C 判定表 を総当たりで比べる。
-- 案B は memberships の role が role_id になっているだけなので (2) で別に比べる。
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id),
by_set AS (SELECT d.id FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id),
by_func AS (SELECT d.id FROM ch12_a.documents d WHERE ch12_a.can_view(7, d.id)),
by_ltree AS (
  SELECT d.id FROM ch12_a.documents d JOIN ch12_a.scopes p ON p.id = d.project_id
   WHERE EXISTS (SELECT 1 FROM ch12_a.memberships m
                   JOIN ch12_a.scopes ms ON ms.id = m.scope_id
                  WHERE m.user_id = 7 AND p.path OPERATOR(public.<@) ms.path)),
by_matview AS (SELECT ea.document_id AS id FROM ch12_c.effective_access ea
                WHERE ea.user_id = 7)
SELECT (SELECT count(*) FROM ((SELECT id FROM by_set  EXCEPT SELECT id FROM by_func)
                              UNION ALL
                              (SELECT id FROM by_func EXCEPT SELECT id FROM by_set)) t)
         AS set_vs_func_diff,
       (SELECT count(*) FROM ((SELECT id FROM by_set   EXCEPT SELECT id FROM by_ltree)
                              UNION ALL
                              (SELECT id FROM by_ltree EXCEPT SELECT id FROM by_set)) t)
         AS set_vs_ltree_diff,
       (SELECT count(*) FROM ((SELECT id FROM by_set     EXCEPT SELECT id FROM by_matview)
                              UNION ALL
                              (SELECT id FROM by_matview EXCEPT SELECT id FROM by_set)) t)
         AS set_vs_matview_diff,
       (SELECT count(*) FROM by_set)     AS set_rows,
       (SELECT count(*) FROM by_func)    AS func_rows,
       (SELECT count(*) FROM by_ltree)   AS ltree_rows,
       (SELECT count(*) FROM by_matview) AS matview_rows;

\echo '=== (2) 利用者7 の「見える文書」が案A と案B で一致すること ==='
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
SELECT count(*) AS a_vs_b_diff,
       (SELECT count(*) FROM a) AS a_rows,
       (SELECT count(*) FROM b) AS b_rows
  FROM ((SELECT id FROM a EXCEPT SELECT id FROM b)
        UNION ALL
        (SELECT id FROM b EXCEPT SELECT id FROM a)) t;

\echo '=== (3) 利用者42（大きなチーム込み）でも一致すること ==='
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 42
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id),
by_set AS (SELECT d.id FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id),
by_matview AS (SELECT ea.document_id AS id FROM ch12_c.effective_access ea
                WHERE ea.user_id = 42)
SELECT count(*) AS set_vs_matview_diff_user42,
       (SELECT count(*) FROM by_set)     AS set_rows,
       (SELECT count(*) FROM by_matview) AS matview_rows
  FROM ((SELECT id FROM by_set     EXCEPT SELECT id FROM by_matview)
        UNION ALL
        (SELECT id FROM by_matview EXCEPT SELECT id FROM by_set)) t;

\echo '=== (4) 🔴 ポリシーが残っていないこと（次の測定を壊さないため。先頭列が 0） ==='
SELECT count(*) AS rls_left_enabled
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname IN ('ch12_a','ch12_b','ch12_c')
   AND (c.relrowsecurity OR c.relforcerowsecurity);

\echo '=== (5) 🔴 章の外にテーブルを作っていないこと（先頭列が 0） ==='
SELECT count(*) AS tables_outside_chapter
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname IN ('public', 'lib') AND c.relkind IN ('r', 'm', 'p');
