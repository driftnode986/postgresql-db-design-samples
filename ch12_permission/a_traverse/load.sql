-- 案A に元データを写す。
--
-- 🔴 元データが空なら、何も消す前に止める。
--    検証の実行順は schema → load なので、元データを作る schema_20_generate.sql が
--    走っていないと、全案が空のまま「全件 OK」になる（第2章で実際に起きた）。
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ch12_r.src_document) THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch12_a.memberships;
TRUNCATE ch12_a.documents;
TRUNCATE ch12_a.users CASCADE;
TRUNCATE ch12_a.scopes CASCADE;

INSERT INTO ch12_a.scopes (id, parent_id, kind, name, path)
SELECT id, parent_id, kind, name, path FROM ch12_r.src_scope ORDER BY id;

INSERT INTO ch12_a.users (id, login)
SELECT id, login FROM ch12_r.src_user ORDER BY id;

INSERT INTO ch12_a.documents (id, project_id, title, created_at)
SELECT id, project_id, title, created_at FROM ch12_r.src_document ORDER BY id;

INSERT INTO ch12_a.memberships (id, user_id, scope_id, role)
SELECT id, user_id, scope_id, role FROM ch12_r.src_membership ORDER BY id;

-- 🔴 インデックスはデータを入れてから作る。
--    付けたまま入れると充填率が 90 から 67 に下がり、
--    サイズが実行のたびに変わる（docs/measurement-rules.yml の sizes）。
--
-- 一覧は「新しい順に 20 件」なので created_at の降順の索引を張る。
-- プロジェクトで絞ってから並べる形も試せるように (project_id, created_at DESC) も張る。
-- 🔴 TRUNCATE では索引は消えないので、入れ直しでも同じ結果になるように先に落とす
--    （落とさないと 2 回目の実行が「既にある」で止まる）。
DROP INDEX IF EXISTS ch12_a.documents_created_at;
DROP INDEX IF EXISTS ch12_a.documents_proj_created;
DROP INDEX IF EXISTS ch12_a.memberships_user;
DROP INDEX IF EXISTS ch12_a.scopes_parent;
DROP INDEX IF EXISTS ch12_a.scopes_path_gist;

CREATE INDEX documents_created_at ON ch12_a.documents (created_at DESC);
CREATE INDEX documents_proj_created ON ch12_a.documents (project_id, created_at DESC);
CREATE INDEX memberships_user ON ch12_a.memberships (user_id);
CREATE INDEX scopes_parent ON ch12_a.scopes (parent_id);
-- ltree 版のための GiST 索引（第4章と同じ）
CREATE INDEX scopes_path_gist ON ch12_a.scopes USING gist (path);

ANALYZE ch12_a.scopes;
ANALYZE ch12_a.users;
ANALYZE ch12_a.documents;
ANALYZE ch12_a.memberships;

\echo '=== 案A の件数 ==='
SELECT (SELECT count(*) FROM ch12_a.scopes)      AS scopes,
       (SELECT count(*) FROM ch12_a.users)       AS users,
       (SELECT count(*) FROM ch12_a.documents)   AS documents,
       (SELECT count(*) FROM ch12_a.memberships) AS memberships;
