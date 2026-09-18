-- 方法 2: 式の一意インデックス。照合順序を変えずに済むが、
-- 問い合わせ側も lower() で書かないとインデックスが効かない
DROP TABLE IF EXISTS ch03_k.tags_lower;
CREATE TABLE ch03_k.tags_lower (name text PRIMARY KEY);
CREATE UNIQUE INDEX tags_lower_name_idx ON ch03_k.tags_lower (lower(name));
INSERT INTO ch03_k.tags_lower VALUES ('PostgreSQL');
