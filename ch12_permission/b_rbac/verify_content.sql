-- run-as: book_owner
-- 案B の中身が元データと一致すること。返す全行の先頭列が 0 になる形で書く。
--
-- 🔴 案B は所属の role を文字列から roles への参照に置き換えているので、
--    照合するときに roles と結合して**文字列に戻して**比べる。
--    置き換えを間違えると（役割の対応がずれると）、ここで差が出る。
-- 🔴 「差が 0」だけでは両方が空でも通るので、元データが空でないことも検査する（第2章の教訓）。
-- 🔴 対称差は必ず括弧で囲む（第9章の教訓）。

\echo '=== (0) 元データが空でないこと（先頭列が 0 であること） ==='
-- 🔴 真偽値ではなく件数で返す（規約は「先頭列が 0」。`f` は 0 と読めない）。
--    空なら 1 を返し、検査が落ちるようにする。
SELECT CASE WHEN (SELECT count(*) FROM ch12_r.src_document) = 0 THEN 1 ELSE 0 END AS source_documents_empty,
       CASE WHEN (SELECT count(*) FROM ch12_r.src_membership) = 0 THEN 1 ELSE 0 END AS source_memberships_empty,
       CASE WHEN (SELECT count(*) FROM ch12_b.documents) = 0 THEN 1 ELSE 0 END AS b_documents_empty,
       CASE WHEN (SELECT count(*) FROM ch12_b.role_permissions) = 0 THEN 1 ELSE 0 END AS b_role_permissions_empty;

\echo '=== (1) scopes の差（先頭列が 0 であること） ==='
SELECT count(*) AS scopes_diff FROM (
  (SELECT id, parent_id, kind, name, path FROM ch12_r.src_scope
   EXCEPT ALL SELECT id, parent_id, kind, name, path FROM ch12_b.scopes)
  UNION ALL
  (SELECT id, parent_id, kind, name, path FROM ch12_b.scopes
   EXCEPT ALL SELECT id, parent_id, kind, name, path FROM ch12_r.src_scope)
) t;

\echo '=== (2) documents の差（先頭列が 0 であること） ==='
SELECT count(*) AS documents_diff FROM (
  (SELECT id, project_id, title, created_at FROM ch12_r.src_document
   EXCEPT ALL SELECT id, project_id, title, created_at FROM ch12_b.documents)
  UNION ALL
  (SELECT id, project_id, title, created_at FROM ch12_b.documents
   EXCEPT ALL SELECT id, project_id, title, created_at FROM ch12_r.src_document)
) t;

\echo '=== (3) memberships の差（役割を文字列に戻して比べる。先頭列が 0 であること） ==='
WITH b AS (
  SELECT m.id, m.user_id, m.scope_id, r.code AS role
    FROM ch12_b.memberships m JOIN ch12_b.roles r ON r.id = m.role_id
)
SELECT count(*) AS memberships_diff FROM (
  (SELECT id, user_id, scope_id, role FROM ch12_r.src_membership
   EXCEPT ALL SELECT id, user_id, scope_id, role FROM b)
  UNION ALL
  (SELECT id, user_id, scope_id, role FROM b
   EXCEPT ALL SELECT id, user_id, scope_id, role FROM ch12_r.src_membership)
) t;

\echo '=== (4) 元データに出てくる役割がすべて roles にあること（先頭列が 0 であること） ==='
SELECT count(*) AS roles_missing FROM (
  SELECT DISTINCT role FROM ch12_r.src_membership
  EXCEPT
  SELECT code FROM ch12_b.roles
) t;
