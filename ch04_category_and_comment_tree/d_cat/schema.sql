-- カテゴリ型（深さ 5）で 3 案を作り、スレッド型と結論が変わるかを見る。
-- 1 つのスキーマに 3 案を並べる（案ごとに表の名前を分ける）。
CREATE SCHEMA ch04_d;

-- 案A
CREATE TABLE ch04_d.a_nodes (
  id         bigint PRIMARY KEY,
  parent_id  bigint REFERENCES ch04_d.a_nodes(id),
  name       text NOT NULL,
  pos        int  NOT NULL
);

-- 案B
CREATE TABLE ch04_d.b_nodes (
  id         bigint PRIMARY KEY,
  parent_id  bigint REFERENCES ch04_d.b_nodes(id),
  name       text NOT NULL,
  pos        int  NOT NULL
);
CREATE TABLE ch04_d.b_paths (
  ancestor_id    bigint NOT NULL REFERENCES ch04_d.b_nodes(id),
  descendant_id  bigint NOT NULL REFERENCES ch04_d.b_nodes(id),
  depth          int    NOT NULL,
  PRIMARY KEY (ancestor_id, descendant_id)
);

-- 案C
CREATE TABLE ch04_d.c_nodes (
  id         bigint PRIMARY KEY,
  parent_id  bigint REFERENCES ch04_d.c_nodes(id),
  path       ltree NOT NULL,
  name       text NOT NULL,
  pos        int  NOT NULL
);
