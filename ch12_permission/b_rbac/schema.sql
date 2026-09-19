-- 案B: 役割と権限の対応をデータで持つ（RBAC）。
--
-- 案A は所属の行に role という文字列を直接持っていた。案B はそれを表に出す。
--
--   roles            役割（admin / editor / viewer）
--   permissions      操作（document.read / document.write / document.delete /
--                    member.invite / project.create ...）
--   role_permissions 「どの役割がどの操作をできるか」の対応
--   memberships      所属。role を文字列ではなく roles への外部キーで持つ
--
-- 🔴 案A との違いは「役割に何ができるか」を**運営が画面から変えられる**ことである。
--    案A で「編集者も招待できるようにする」を実現するには、判定しているコードを直して
--    デプロイすることになる。案B なら role_permissions に 1 行入れるだけで済む。
--
-- 🔴 一覧の絞り込み（この章の主題）に効くかどうかは、実測で確かめる（21_read_list.sql）。
--    案B が変えるのは「この人はこの操作をできるか」の側であって、
--    「この人が見られる文書はどれか」の側ではない、という見込みがある。
CREATE SCHEMA IF NOT EXISTS ch12_b;

DROP TABLE IF EXISTS ch12_b.memberships;
DROP TABLE IF EXISTS ch12_b.role_permissions;
DROP TABLE IF EXISTS ch12_b.permissions;
DROP TABLE IF EXISTS ch12_b.roles;
DROP TABLE IF EXISTS ch12_b.documents;
DROP TABLE IF EXISTS ch12_b.users;
DROP TABLE IF EXISTS ch12_b.scopes;

CREATE TABLE ch12_b.scopes (
  id        bigint PRIMARY KEY,
  parent_id bigint REFERENCES ch12_b.scopes(id),
  kind      text   NOT NULL,
  name      text   NOT NULL,
  path      public.ltree NOT NULL
);

CREATE TABLE ch12_b.users (
  id    bigint PRIMARY KEY,
  login text   NOT NULL
);

CREATE TABLE ch12_b.documents (
  id         bigint      PRIMARY KEY,
  project_id bigint      NOT NULL REFERENCES ch12_b.scopes(id),
  title      text        NOT NULL,
  created_at timestamptz NOT NULL
);

-- 役割。code が画面と API で使う名前
CREATE TABLE ch12_b.roles (
  id    int  PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  code  text NOT NULL UNIQUE,
  label text NOT NULL
);

-- 操作。「資源の種類」と「動作」に分けて持つ
CREATE TABLE ch12_b.permissions (
  id       int  PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  code     text NOT NULL UNIQUE,
  resource text NOT NULL,
  action   text NOT NULL
);

-- 役割と操作の対応。これが「運営が画面から変えられる」部分
CREATE TABLE ch12_b.role_permissions (
  role_id       int NOT NULL REFERENCES ch12_b.roles(id) ON DELETE CASCADE,
  permission_id int NOT NULL REFERENCES ch12_b.permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- 所属。role を文字列ではなく roles への参照で持つ。
-- 🔴 これが案A との唯一の構造上の違いである（一覧の問い合わせは同じ形になる）。
CREATE TABLE ch12_b.memberships (
  id       bigint PRIMARY KEY,
  user_id  bigint NOT NULL REFERENCES ch12_b.users(id),
  scope_id bigint NOT NULL REFERENCES ch12_b.scopes(id),
  role_id  int    NOT NULL REFERENCES ch12_b.roles(id)
);

-- 「この人はこの対象でこの操作ができるか」を返す関数。
-- 案A には無い問いで、これが案B の存在理由である。
CREATE FUNCTION ch12_b.can(p_user bigint, p_scope bigint, p_perm text)
RETURNS boolean AS $$
  SELECT EXISTS (
    WITH RECURSIVE anc AS (
      SELECT s.id, s.parent_id FROM ch12_b.scopes s WHERE s.id = p_scope
      UNION ALL
      SELECT s.id, s.parent_id FROM ch12_b.scopes s JOIN anc ON s.id = anc.parent_id
    )
    SELECT 1
      FROM ch12_b.memberships m
      JOIN anc ON anc.id = m.scope_id
      JOIN ch12_b.role_permissions rp ON rp.role_id = m.role_id
      JOIN ch12_b.permissions p ON p.id = rp.permission_id
     WHERE m.user_id = p_user AND p.code = p_perm);
$$ LANGUAGE sql STABLE;

GRANT EXECUTE ON FUNCTION ch12_b.can(bigint, bigint, text) TO book_app;
