-- 案C: ルートから自分までの経路を 1 列に持つ（ltree）
CREATE SCHEMA ch04_c;

CREATE EXTENSION IF NOT EXISTS ltree;

CREATE TABLE ch04_c.nodes (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_id  bigint REFERENCES ch04_c.nodes(id),
  -- ルートから自分までの id を並べた経路（末尾が自分の id）
  -- ラベルに名前ではなく id を入れる。ラベルに使える文字はデータベースのロケールで
  -- 変わるので、名前を入れると開発機では通り、ロケールの違うサーバーでは落ちる
  path       ltree NOT NULL,
  body       text  NOT NULL,
  pos        int   NOT NULL DEFAULT 0,
  CONSTRAINT nodes_no_self_parent CHECK (parent_id <> id)
);
