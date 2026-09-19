-- run-as: book_owner
-- 案C の元データの写しが、元データと一致すること。返す全行の先頭列が 0 になる形で書く。
--
-- 🔴 判定表（effective_access）の一致は 50_drift.sql が検査する（全行の突き合わせが要り、
--    数十秒かかるため分けている）。ここは写した 4 表だけを見る。
-- 🔴 「差が 0」だけでは両方が空でも通るので、元データが空でないことも検査する（第2章の教訓）。

\echo '=== (0) 元データが空でないこと（先頭列が 0 であること） ==='
-- 🔴 真偽値ではなく件数で返す（規約は「先頭列が 0」。`f` は 0 と読めない）。
--    空なら 1 を返し、検査が落ちるようにする。
SELECT CASE WHEN (SELECT count(*) FROM ch12_r.src_document) = 0 THEN 1 ELSE 0 END AS source_documents_empty,
       CASE WHEN (SELECT count(*) FROM ch12_r.src_membership) = 0 THEN 1 ELSE 0 END AS source_memberships_empty,
       CASE WHEN (SELECT count(*) FROM ch12_c.documents) = 0 THEN 1 ELSE 0 END AS c_documents_empty;

\echo '=== (1) scopes の差（先頭列が 0 であること） ==='
SELECT count(*) AS scopes_diff FROM (
  (SELECT id, parent_id, kind, name, path FROM ch12_r.src_scope
   EXCEPT ALL SELECT id, parent_id, kind, name, path FROM ch12_c.scopes)
  UNION ALL
  (SELECT id, parent_id, kind, name, path FROM ch12_c.scopes
   EXCEPT ALL SELECT id, parent_id, kind, name, path FROM ch12_r.src_scope)
) t;

\echo '=== (2) documents の差（先頭列が 0 であること） ==='
SELECT count(*) AS documents_diff FROM (
  (SELECT id, project_id, title, created_at FROM ch12_r.src_document
   EXCEPT ALL SELECT id, project_id, title, created_at FROM ch12_c.documents)
  UNION ALL
  (SELECT id, project_id, title, created_at FROM ch12_c.documents
   EXCEPT ALL SELECT id, project_id, title, created_at FROM ch12_r.src_document)
) t;

\echo '=== (3) memberships の差（先頭列が 0 であること） ==='
SELECT count(*) AS memberships_diff FROM (
  (SELECT id, user_id, scope_id, role FROM ch12_r.src_membership
   EXCEPT ALL SELECT id, user_id, scope_id, role FROM ch12_c.memberships)
  UNION ALL
  (SELECT id, user_id, scope_id, role FROM ch12_c.memberships
   EXCEPT ALL SELECT id, user_id, scope_id, role FROM ch12_r.src_membership)
) t;

-- 🔴 判定表（effective_access）が空でないことは、ここでは検査しない。
--    このファイルは load.sql の直後に走り、判定表を作るのは 15_build.sql なので、
--    この時点では空であるのが正しい。判定表の中身は
--    15_build.sql の (6) と 50_drift.sql が検査する。
--    （最初はここに「空でないこと」の検査を置いたが、常に失敗する検査になっていた。
--      常に赤い検査は、本当の違反を埋もれさせる。）
