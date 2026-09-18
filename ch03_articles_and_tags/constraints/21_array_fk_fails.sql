-- expect-error: 42804
-- 案B では、配列の要素にタグのマスタへの外部キーを張れない
CREATE SCHEMA IF NOT EXISTS ch03_k;
DROP TABLE IF EXISTS ch03_k.tags_master;
CREATE TABLE ch03_k.tags_master (name text PRIMARY KEY);
CREATE TABLE ch03_k.articles_fk (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tags  text[] NOT NULL REFERENCES ch03_k.tags_master(name)
);
