-- 案C に元データを写す。判定表（effective_access）はまだ作らない。
-- 初期構築は 15_build.sql で、時間と行数を測りながら作る。
--
-- 🔴 元データが空なら、何も消す前に止める（第2章の教訓）。
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ch12_r.src_document) THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch12_c.effective_access;
TRUNCATE ch12_c.memberships;
TRUNCATE ch12_c.documents;
TRUNCATE ch12_c.users CASCADE;
TRUNCATE ch12_c.scopes CASCADE;

INSERT INTO ch12_c.scopes (id, parent_id, kind, name, path)
SELECT id, parent_id, kind, name, path FROM ch12_r.src_scope ORDER BY id;

INSERT INTO ch12_c.users (id, login)
SELECT id, login FROM ch12_r.src_user ORDER BY id;

INSERT INTO ch12_c.documents (id, project_id, title, created_at)
SELECT id, project_id, title, created_at FROM ch12_r.src_document ORDER BY id;

INSERT INTO ch12_c.memberships (id, user_id, scope_id, role)
SELECT id, user_id, scope_id, role FROM ch12_r.src_membership ORDER BY id;

-- 🔴 索引はデータを入れてから作る（充填率が変わるため）
-- 🔴 TRUNCATE では索引は消えないので、入れ直しでも同じ結果になるように先に落とす
--    （落とさないと 2 回目の実行が「既にある」で止まる）。
DROP INDEX IF EXISTS ch12_c.documents_created_at;
DROP INDEX IF EXISTS ch12_c.documents_proj_created;
DROP INDEX IF EXISTS ch12_c.memberships_user;
DROP INDEX IF EXISTS ch12_c.scopes_parent;
DROP INDEX IF EXISTS ch12_c.scopes_path_gist;

CREATE INDEX documents_created_at ON ch12_c.documents (created_at DESC);
CREATE INDEX documents_proj_created ON ch12_c.documents (project_id, created_at DESC);
CREATE INDEX memberships_user ON ch12_c.memberships (user_id);
CREATE INDEX scopes_parent ON ch12_c.scopes (parent_id);
CREATE INDEX scopes_path_gist ON ch12_c.scopes USING gist (path);

ANALYZE ch12_c.scopes;
ANALYZE ch12_c.users;
ANALYZE ch12_c.documents;
ANALYZE ch12_c.memberships;

\echo '=== 案C の件数（判定表はまだ空） ==='
SELECT (SELECT count(*) FROM ch12_c.scopes)            AS scopes,
       (SELECT count(*) FROM ch12_c.users)             AS users,
       (SELECT count(*) FROM ch12_c.documents)         AS documents,
       (SELECT count(*) FROM ch12_c.memberships)       AS memberships,
       (SELECT count(*) FROM ch12_c.effective_access)  AS effective_access;
