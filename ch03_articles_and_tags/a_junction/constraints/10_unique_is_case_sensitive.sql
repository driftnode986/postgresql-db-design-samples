-- run-as: book_owner
-- 通常の UNIQUE では、大文字小文字だけが違うタグが別の行として入る
DROP TABLE IF EXISTS ch03_a.tags_plain;
CREATE TABLE ch03_a.tags_plain (name text PRIMARY KEY);
INSERT INTO ch03_a.tags_plain VALUES ('PostgreSQL'), ('postgresql'), ('POSTGRESQL');
SELECT count(*) AS rows_inserted FROM ch03_a.tags_plain;
