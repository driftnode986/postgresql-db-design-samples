-- run-as: book_owner
-- データベースのロール（GRANT）と、アプリの権限の切り分け。
--
-- この章のここまでは「アプリの権限」（誰がどの文書を見られるか）の話だった。
-- それとは別に、データベースにもロールと権限がある。混ぜると事故になる。
--
-- ここでは、その 2 つが交わる場所を 1 つ示す:
-- 「表への INSERT を GRANT したのに、INSERT が権限不足で失敗する」。
--
-- 🔴 権限不足の実演に book_app を使わない。book_app には
--    ALTER DEFAULT PRIVILEGES でシーケンスの USAGE が自動で付くので再現しない。
--    何も権限を持たない book_guest を使う（CLAUDE.md の規約）。
CREATE SCHEMA IF NOT EXISTS ch12_g;

DROP TABLE IF EXISTS ch12_g.t_serial;
DROP TABLE IF EXISTS ch12_g.t_identity;

-- 旧来の書き方。id の既定値は nextval('t_serial_id_seq') で、
-- **シーケンスという別のオブジェクト**を読む
CREATE TABLE ch12_g.t_serial (
  id   serial PRIMARY KEY,
  memo text
);

-- 本書の規約の書き方。id はテーブルの一部として生成される
CREATE TABLE ch12_g.t_identity (
  id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  memo text
);

-- book_guest に与えるのは「スキーマを使う」と「2 つの表に INSERT する」だけ。
-- シーケンスの権限は**与えない**。
GRANT USAGE ON SCHEMA ch12_g TO book_guest;
GRANT INSERT ON ch12_g.t_serial, ch12_g.t_identity TO book_guest;

\echo '=== book_guest に与えた権限（シーケンスは含まれない） ==='
SELECT c.relname, c.relkind,
       -- 🔴 pg_get_acl() は 18 で追加された関数。ACL を行で読める
       coalesce((SELECT string_agg(a.privilege_type, ',' ORDER BY a.privilege_type)
                   FROM aclexplode(c.relacl) a
                  WHERE a.grantee = 'book_guest'::regrole), '(なし)') AS granted_to_guest
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'ch12_g' AND c.relkind IN ('r', 'S')
 ORDER BY c.relkind, c.relname;
