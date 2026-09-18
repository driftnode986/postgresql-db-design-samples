-- 通常の UNIQUE では、大文字小文字だけが違うタグが別の行として入る
CREATE SCHEMA IF NOT EXISTS ch03_k;
DROP TABLE IF EXISTS ch03_k.tags_plain;
CREATE TABLE ch03_k.tags_plain (name text PRIMARY KEY);
INSERT INTO ch03_k.tags_plain VALUES ('PostgreSQL'), ('postgresql'), ('POSTGRESQL');
SELECT count(*) AS rows_inserted FROM ch03_k.tags_plain;
