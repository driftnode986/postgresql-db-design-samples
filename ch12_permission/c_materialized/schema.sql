-- 案C: 判定結果を実体化する（effective_access）。
--
-- 「誰が・どの文書を・どの役割で見られるか」を 1 行ずつ持つ表を作る。
-- 読むときは階層をたどらず、この表を user_id で引くだけになる。
--
-- 🔴 行数は「利用者 × その人が見られる文書」の合計になる。
--    全員が入る大きなチームが 1 つあると、ここで
--    「利用者の数 × そのチーム配下の文書の数」の行が生まれる。
--    元データの文書 10 万件に対して、この表が何行になるかを実測する（15_build.sql）。
CREATE SCHEMA IF NOT EXISTS ch12_c;

DROP TABLE IF EXISTS ch12_c.effective_access;
DROP TABLE IF EXISTS ch12_c.memberships;
DROP TABLE IF EXISTS ch12_c.documents;
DROP TABLE IF EXISTS ch12_c.users;
DROP TABLE IF EXISTS ch12_c.scopes;

CREATE TABLE ch12_c.scopes (
  id        bigint PRIMARY KEY,
  parent_id bigint REFERENCES ch12_c.scopes(id),
  kind      text   NOT NULL,
  name      text   NOT NULL,
  path      public.ltree NOT NULL
);

CREATE TABLE ch12_c.users (
  id    bigint PRIMARY KEY,
  login text   NOT NULL
);

CREATE TABLE ch12_c.documents (
  id         bigint      PRIMARY KEY,
  project_id bigint      NOT NULL REFERENCES ch12_c.scopes(id),
  title      text        NOT NULL,
  created_at timestamptz NOT NULL
);

CREATE TABLE ch12_c.memberships (
  id       bigint PRIMARY KEY,
  user_id  bigint NOT NULL REFERENCES ch12_c.users(id),
  scope_id bigint NOT NULL REFERENCES ch12_c.scopes(id),
  role     text   NOT NULL
);

-- 判定結果。
--
-- 🔴 created_at をここに複製している。複製しないと、一覧の
--    「新しい順に 20 件」のために documents と結合して並べ替えることになり、
--    実体化した意味が薄れる。代わりに「文書の作成日時が変わったら
--    この表も直す」という義務が生まれる（案C の負債の 1 つ）。
CREATE TABLE ch12_c.effective_access (
  user_id     bigint      NOT NULL,
  document_id bigint      NOT NULL,
  role        text        NOT NULL,
  created_at  timestamptz NOT NULL,
  PRIMARY KEY (user_id, document_id)
);
