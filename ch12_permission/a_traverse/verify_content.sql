-- run-as: book_owner
-- 案A の中身が元データと一致すること。返す全行の先頭列が 0 になる形で書く。
--
-- 🔴 「差が 0」だけでは、両方が空でも通ってしまう（第2章で全案が空のまま
--    54 件 OK になった）。**元データが空でないこと**も同時に検査する。
-- 🔴 対称差は必ず括弧で囲む。囲まないと EXCEPT と UNION ALL が左結合になり、
--    片方向にしか働かない（第9章で 5 ファイルが同じ誤りだった）。

\echo '=== (0) 元データが空でないこと（先頭列が 0 であること） ==='
-- 🔴 真偽値ではなく件数で返す（規約は「先頭列が 0」。`f` は 0 と読めない）。
--    空なら 1 を返し、検査が落ちるようにする。
SELECT CASE WHEN (SELECT count(*) FROM ch12_r.src_document) = 0 THEN 1 ELSE 0 END AS source_documents_empty,
       CASE WHEN (SELECT count(*) FROM ch12_r.src_membership) = 0 THEN 1 ELSE 0 END AS source_memberships_empty,
       CASE WHEN (SELECT count(*) FROM ch12_a.documents) = 0 THEN 1 ELSE 0 END AS a_documents_empty;

\echo '=== (1) scopes の差（先頭列が 0 であること） ==='
SELECT count(*) AS scopes_diff FROM (
  (SELECT id, parent_id, kind, name, path FROM ch12_r.src_scope
   EXCEPT ALL SELECT id, parent_id, kind, name, path FROM ch12_a.scopes)
  UNION ALL
  (SELECT id, parent_id, kind, name, path FROM ch12_a.scopes
   EXCEPT ALL SELECT id, parent_id, kind, name, path FROM ch12_r.src_scope)
) t;

\echo '=== (2) documents の差（先頭列が 0 であること） ==='
SELECT count(*) AS documents_diff FROM (
  (SELECT id, project_id, title, created_at FROM ch12_r.src_document
   EXCEPT ALL SELECT id, project_id, title, created_at FROM ch12_a.documents)
  UNION ALL
  (SELECT id, project_id, title, created_at FROM ch12_a.documents
   EXCEPT ALL SELECT id, project_id, title, created_at FROM ch12_r.src_document)
) t;

\echo '=== (3) memberships の差（先頭列が 0 であること） ==='
SELECT count(*) AS memberships_diff FROM (
  (SELECT id, user_id, scope_id, role FROM ch12_r.src_membership
   EXCEPT ALL SELECT id, user_id, scope_id, role FROM ch12_a.memberships)
  UNION ALL
  (SELECT id, user_id, scope_id, role FROM ch12_a.memberships
   EXCEPT ALL SELECT id, user_id, scope_id, role FROM ch12_r.src_membership)
) t;
