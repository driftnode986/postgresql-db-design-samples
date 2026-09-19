-- 案B に元データを写す。所属の role（文字列）を roles への参照に置き換える。
--
-- 🔴 元データが空なら、何も消す前に止める（第2章の教訓）。
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ch12_r.src_document) THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch12_b.memberships;
TRUNCATE ch12_b.role_permissions;
TRUNCATE ch12_b.permissions RESTART IDENTITY CASCADE;
TRUNCATE ch12_b.roles RESTART IDENTITY CASCADE;
TRUNCATE ch12_b.documents;
TRUNCATE ch12_b.users CASCADE;
TRUNCATE ch12_b.scopes CASCADE;

INSERT INTO ch12_b.scopes (id, parent_id, kind, name, path)
SELECT id, parent_id, kind, name, path FROM ch12_r.src_scope ORDER BY id;

INSERT INTO ch12_b.users (id, login)
SELECT id, login FROM ch12_r.src_user ORDER BY id;

INSERT INTO ch12_b.documents (id, project_id, title, created_at)
SELECT id, project_id, title, created_at FROM ch12_r.src_document ORDER BY id;

-- 役割。元データに出てくる role の種類から作る（admin は所属が無くても定義する）
INSERT INTO ch12_b.roles (code, label) VALUES
  ('admin',  '管理者'),
  ('editor', '編集者'),
  ('viewer', '閲覧者');

INSERT INTO ch12_b.permissions (code, resource, action) VALUES
  ('document.read',   'document', 'read'),
  ('document.write',  'document', 'write'),
  ('document.delete', 'document', 'delete'),
  ('member.invite',   'member',   'invite'),
  ('project.create',  'project',  'create');

-- 役割と操作の対応。
--   閲覧者 … 読む
--   編集者 … 読む・書く
--   管理者 … 全部
INSERT INTO ch12_b.role_permissions (role_id, permission_id)
SELECT r.id, p.id
  FROM ch12_b.roles r, ch12_b.permissions p
 WHERE (r.code = 'viewer' AND p.code IN ('document.read'))
    OR (r.code = 'editor' AND p.code IN ('document.read', 'document.write'))
    OR (r.code = 'admin')
 ORDER BY r.id, p.id;

INSERT INTO ch12_b.memberships (id, user_id, scope_id, role_id)
SELECT m.id, m.user_id, m.scope_id, r.id
  FROM ch12_r.src_membership m
  JOIN ch12_b.roles r ON r.code = m.role
 ORDER BY m.id;

-- 🔴 索引はデータを入れてから作る（充填率が変わるため）
-- 🔴 TRUNCATE では索引は消えないので、入れ直しでも同じ結果になるように先に落とす
--    （落とさないと 2 回目の実行が「既にある」で止まる）。
DROP INDEX IF EXISTS ch12_b.documents_created_at;
DROP INDEX IF EXISTS ch12_b.documents_proj_created;
DROP INDEX IF EXISTS ch12_b.memberships_user;
DROP INDEX IF EXISTS ch12_b.scopes_parent;
DROP INDEX IF EXISTS ch12_b.scopes_path_gist;

CREATE INDEX documents_created_at ON ch12_b.documents (created_at DESC);
CREATE INDEX documents_proj_created ON ch12_b.documents (project_id, created_at DESC);
CREATE INDEX memberships_user ON ch12_b.memberships (user_id);
CREATE INDEX scopes_parent ON ch12_b.scopes (parent_id);
CREATE INDEX scopes_path_gist ON ch12_b.scopes USING gist (path);

ANALYZE ch12_b.scopes;
ANALYZE ch12_b.users;
ANALYZE ch12_b.documents;
ANALYZE ch12_b.roles;
ANALYZE ch12_b.permissions;
ANALYZE ch12_b.role_permissions;
ANALYZE ch12_b.memberships;

\echo '=== 案B の件数 ==='
SELECT (SELECT count(*) FROM ch12_b.scopes)           AS scopes,
       (SELECT count(*) FROM ch12_b.users)            AS users,
       (SELECT count(*) FROM ch12_b.documents)        AS documents,
       (SELECT count(*) FROM ch12_b.memberships)      AS memberships,
       (SELECT count(*) FROM ch12_b.roles)            AS roles,
       (SELECT count(*) FROM ch12_b.permissions)      AS permissions,
       (SELECT count(*) FROM ch12_b.role_permissions) AS role_permissions;

\echo '=== 役割と操作の対応（案B が表に出したもの） ==='
SELECT r.code AS role, string_agg(p.code, ', ' ORDER BY p.code) AS permissions
  FROM ch12_b.roles r
  LEFT JOIN ch12_b.role_permissions rp ON rp.role_id = r.id
  LEFT JOIN ch12_b.permissions p ON p.id = rp.permission_id
 GROUP BY r.code ORDER BY r.code;
