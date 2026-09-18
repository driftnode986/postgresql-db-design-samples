-- run-as: book_owner
-- expect-error: 42804
-- 案B では、配列の要素にタグのマスタへの外部キーを張れない
DROP TABLE IF EXISTS ch03_b.tags_master;
CREATE TABLE ch03_b.tags_master (name text PRIMARY KEY);
CREATE TABLE ch03_b.articles_fk (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tags  text[] NOT NULL REFERENCES ch03_b.tags_master(name)
);
