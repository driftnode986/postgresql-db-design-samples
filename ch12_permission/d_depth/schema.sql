-- run-as: book_owner
-- 階層の深さを変えたときの、案A（再帰 CTE）の時間を測るための専用データ。
--
-- 企画は「階層の深さが選び方の軸になる」としていた。それを確かめる。
--
-- 形: 一本道の鎖を 200 本、各鎖の深さを 12 にする（節点 2,400）。
--     最深部に文書 10,000 件。利用者1 は各鎖の**最上位**に所属する
--     （= 文書に届くまで深さぶんたどる必要がある）。
--
-- 🔴 深さごとに別の階層を作るのではなく、1 つの階層を作って
--    再帰の上限を `lvl < d` で切って測る。こうすると、
--    深さ以外の条件（文書の数・所属の数・キャッシュの温まり方）が揃う。
CREATE SCHEMA IF NOT EXISTS ch12_d;

DROP TABLE IF EXISTS ch12_d.memberships;
DROP TABLE IF EXISTS ch12_d.documents;
DROP TABLE IF EXISTS ch12_d.scopes;

CREATE TABLE ch12_d.scopes (
  id        bigint PRIMARY KEY,
  parent_id bigint REFERENCES ch12_d.scopes(id),
  lvl       int    NOT NULL,       -- 鎖の中の深さ（1 が最上位）
  chain     int    NOT NULL        -- どの鎖か
);

CREATE TABLE ch12_d.documents (
  id         bigint      PRIMARY KEY,
  project_id bigint      NOT NULL REFERENCES ch12_d.scopes(id),
  title      text        NOT NULL,
  created_at timestamptz NOT NULL
);

CREATE TABLE ch12_d.memberships (
  id       bigint PRIMARY KEY,
  user_id  bigint NOT NULL,
  scope_id bigint NOT NULL REFERENCES ch12_d.scopes(id),
  role     text   NOT NULL
);
