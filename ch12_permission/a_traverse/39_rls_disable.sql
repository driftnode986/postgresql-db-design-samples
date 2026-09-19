-- run-as: book_owner
-- ポリシーを外して、案A を元の状態に戻す。
--
-- 🔴 これを忘れると、次に案A を測ったときに「ポリシーが絞ったあとの行」を測ることになり、
--    比較が壊れる（確認記録 §6 で 235 ms が 4 ms に見えた事故の再現）。
--    run_measure.sh は測定の最後にこれを実行し、20_read_func.sql の冒頭の検査
--    （relrowsecurity が 0 件）で戻っていることを確かめる。
\timing on

DROP POLICY IF EXISTS doc_visible ON ch12_a.documents;
DROP POLICY IF EXISTS doc_insertable ON ch12_a.documents;
ALTER TABLE ch12_a.documents NO FORCE ROW LEVEL SECURITY;
ALTER TABLE ch12_a.documents DISABLE ROW LEVEL SECURITY;

\echo '=== 🔴 ポリシーが外れたこと（すべて 0 / false であること） ==='
SELECT (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'ch12_a' AND (c.relrowsecurity OR c.relforcerowsecurity))
       AS rls_enabled_tables,
       (SELECT count(*) FROM pg_policy p
          JOIN pg_class c ON c.oid = p.polrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'ch12_a') AS policies;

-- 🔴 31_rls_read.sql の covert channel の実演で挿入した行を消す。
--    実演の中で消そうとしても、DELETE のポリシーが無いので
--    **エラーにならず 0 行消して終わる**（公式が言う silently suppressed）。
--    ポリシーを外したこの時点で、所有者として消す。
DELETE FROM ch12_a.documents
 WHERE title IN ('probe-free', 'probe-hidden');

\echo '=== 🔴 実演で挿入した行が残っていないこと（先頭列が 0 であること） ==='
SELECT count(*) AS probe_rows_left
  FROM ch12_a.documents WHERE title IN ('probe-free', 'probe-hidden');

\echo '=== 🔴 案A の文書が元データと同じ件数であること（先頭列が 0 であること） ==='
-- 実演で 1 件でも増えたまま残ると、あとの一覧の突き合わせが 674 対 673 の差を出す。
SELECT count(*) AS documents_diff FROM (
  (SELECT id FROM ch12_r.src_document EXCEPT SELECT id FROM ch12_a.documents)
  UNION ALL
  (SELECT id FROM ch12_a.documents EXCEPT SELECT id FROM ch12_r.src_document)
) t;

\echo '=== 🔴 book_app から全件が見えるようになったこと（先頭列が 0 であること） ==='
SELECT count(*) AS documents_missing_after_disable
  FROM (SELECT id FROM ch12_r.src_document
        EXCEPT SELECT id FROM ch12_a.documents) t;
