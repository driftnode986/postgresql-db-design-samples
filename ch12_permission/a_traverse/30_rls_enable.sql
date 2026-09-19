-- run-as: book_owner
-- 案A の判定を、問い合わせではなく**行レベルセキュリティのポリシー**に書く。
--
-- ここまでの 3 つの書き方（関数・集合・ltree）は、すべて「アプリが正しい WHERE を書く」
-- という前提に立っていた。書き忘れたら全件が見える。
-- ポリシーに書けば、素の `SELECT * FROM documents` でも絞られる。
--
-- 🔴 測定は book_app で行う。公式マニュアル（ddl-rowsecurity）:
--    「Superusers and roles with the BYPASSRLS attribute always bypass the row security
--     system ... Table owners normally bypass row security as well」
--    所有者も迂回するので、FORCE ROW LEVEL SECURITY を付けて所有者にも効かせる。
--
-- 🔴 ポリシーが参照する表（memberships / scopes）に、
--    ポリシーを使うロールの SELECT 権限が必要である。公式（sql-createpolicy）:
--    「users who are using a given policy must be able to access any tables or functions
--     referenced in the expression or they will simply receive a permission denied error」
--    （book_app は ALTER DEFAULT PRIVILEGES で既に持っているが、明示しておく）
--
-- 🔴 このファイルは ch12_a の documents にポリシーを付ける。
--    ポリシーを残したまま関数方式（20_read_func.sql）を測ると、
--    関数は「ポリシーが絞ったあとの行」にしか適用されず、
--    235 ms が 4 ms に見える（確認記録 §6 で実際に踏んだ）。
--    そのため run_measure.sh は 20〜22 の測定をすべて終えてからこれを実行し、
--    最後に 39_rls_disable.sql でポリシーを外す。
\timing on

GRANT SELECT ON ch12_a.memberships, ch12_a.scopes, ch12_a.documents TO book_app;

ALTER TABLE ch12_a.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE ch12_a.documents FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS doc_visible ON ch12_a.documents;
CREATE POLICY doc_visible ON ch12_a.documents FOR SELECT USING (
  project_id IN (
    WITH RECURSIVE vis AS (
      SELECT m.scope_id AS id
        FROM ch12_a.memberships m
       WHERE m.user_id = current_setting('app.user_id')::bigint
      UNION
      SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id
    )
    SELECT id FROM vis));

-- 書き込みのポリシーも付ける。
--
-- 🔴 SELECT のポリシーしか付けないと、INSERT は**すべて**拒否される
--    （「ポリシーが無い操作は許可されない」ため）。実在するサービスでは
--    「自分が編集者として所属するプロジェクトには文書を作れる」形になるので、
--    それを書く。31_rls_read.sql の covert channel の実演は、
--    このポリシーを通ったあとに一意制約の検査に当たることを見るものである。
DROP POLICY IF EXISTS doc_insertable ON ch12_a.documents;
CREATE POLICY doc_insertable ON ch12_a.documents FOR INSERT WITH CHECK (
  project_id IN (
    WITH RECURSIVE vis AS (
      SELECT m.scope_id AS id
        FROM ch12_a.memberships m
       WHERE m.user_id = current_setting('app.user_id')::bigint
      UNION
      SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id
    )
    SELECT id FROM vis));

\echo '=== ポリシーが付いたこと ==='
SELECT c.relname, c.relrowsecurity AS row_security, c.relforcerowsecurity AS forced,
       (SELECT count(*) FROM pg_policy p WHERE p.polrelid = c.oid) AS policies
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'ch12_a' AND c.relname = 'documents';

\echo '=== 🔴 所有者にも効くこと（FORCE を付けたので book_owner でもエラーになる） ==='
-- app.user_id を設定していないセッションでは、ポリシー式の
-- current_setting('app.user_id') が失敗する。所有者も迂回できない。
-- 案C の初期構築がこれで止まった（確認記録 §6）。
-- 🔴 期待するエラー: 42704 unrecognized configuration parameter "app.user_id"
--    ここでは止めたくないので、例外を捕まえて文面だけを出す。
DO $$
BEGIN
  PERFORM count(*) FROM ch12_a.documents;
  RAISE NOTICE '🔴 想定外: app.user_id 未設定でも読めた（FORCE が効いていない）';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '想定どおりエラー: % (SQLSTATE %)', SQLERRM, SQLSTATE;
END $$;
