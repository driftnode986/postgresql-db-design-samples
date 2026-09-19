-- 案A: 判定結果を持たず、必要なときに階層をたどる。
--
-- テーブルは元データの写しだけで、権限判定のための入れ物を持たない。
-- 所属を 1 行足せば、その配下の文書がすぐ見えるようになる（作り直しが要らない）。
CREATE SCHEMA IF NOT EXISTS ch12_a;

DROP TABLE IF EXISTS ch12_a.memberships;
DROP TABLE IF EXISTS ch12_a.documents;
DROP TABLE IF EXISTS ch12_a.users;
DROP TABLE IF EXISTS ch12_a.scopes;

CREATE TABLE ch12_a.scopes (
  id        bigint PRIMARY KEY,
  parent_id bigint REFERENCES ch12_a.scopes(id),
  kind      text   NOT NULL,
  name      text   NOT NULL,
  path      public.ltree NOT NULL
);

CREATE TABLE ch12_a.users (
  id    bigint PRIMARY KEY,
  login text   NOT NULL
);

CREATE TABLE ch12_a.documents (
  id         bigint      PRIMARY KEY,
  project_id bigint      NOT NULL REFERENCES ch12_a.scopes(id),
  title      text        NOT NULL,
  created_at timestamptz NOT NULL
);

CREATE TABLE ch12_a.memberships (
  id       bigint PRIMARY KEY,
  user_id  bigint NOT NULL REFERENCES ch12_a.users(id),
  scope_id bigint NOT NULL REFERENCES ch12_a.scopes(id),
  role     text   NOT NULL
);

-- 案A の「1 件ずつ可否を返す関数」。
--
-- 🔴 これは**アプリに権限判定の関数があるサービスから持ち込まれる形**である。
--    要件文だけを渡したときに AI が書く形ではない（3 本とも集合として書いた。
--    docs/research/ch12_first_idea.md）。既存の判定ロジックをそのまま一覧に使うと
--    何が起きるかを見るために置く。
--
-- STABLE を付けてあるので同じ引数なら 1 文の中で再利用されうるが、
-- 引数が行ごとに変わる（id を渡す）ので、行の数だけ実行される。
CREATE FUNCTION ch12_a.can_view(p_user bigint, p_doc bigint) RETURNS boolean AS $$
  SELECT EXISTS (
    WITH RECURSIVE anc AS (
      SELECT s.id, s.parent_id
        FROM ch12_a.scopes s
       WHERE s.id = (SELECT project_id FROM ch12_a.documents WHERE id = p_doc)
      UNION ALL
      SELECT s.id, s.parent_id
        FROM ch12_a.scopes s JOIN anc ON s.id = anc.parent_id
    )
    SELECT 1 FROM ch12_a.memberships m JOIN anc ON anc.id = m.scope_id
     WHERE m.user_id = p_user);
$$ LANGUAGE sql STABLE;

GRANT EXECUTE ON FUNCTION ch12_a.can_view(bigint, bigint) TO book_app;
