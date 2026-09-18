-- run-as: book_owner
-- 自己参照の外部キーは、循環を拒否しない。
-- 3 ノードの最小の木で確かめる。
CREATE SCHEMA IF NOT EXISTS ch04_x;
DROP TABLE IF EXISTS ch04_x.nodes;
CREATE TABLE ch04_x.nodes (
  id         bigint PRIMARY KEY,
  parent_id  bigint REFERENCES ch04_x.nodes(id),
  name       text NOT NULL
);
INSERT INTO ch04_x.nodes VALUES (1, NULL, 'root'), (2, 1, 'child'), (3, 2, 'grand');

-- ルートの親を、自分の孫にする。外部キーは参照先が在るかしか見ないので、通ってしまう
UPDATE ch04_x.nodes SET parent_id = 3 WHERE id = 1;

-- 1 -> 2 -> 3 -> 1 の輪ができている
SELECT id, parent_id, name FROM ch04_x.nodes ORDER BY id;
