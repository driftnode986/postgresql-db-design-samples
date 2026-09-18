-- run-as: book_owner
-- 方法 1: 大文字小文字を区別しない照合順序を作り、その照合順序で一意制約を張る
CREATE COLLATION IF NOT EXISTS ch03_a.case_insensitive
  (provider = icu, locale = 'und-u-ks-level2', deterministic = false);
DROP TABLE IF EXISTS ch03_a.tags_ci;
CREATE TABLE ch03_a.tags_ci (
  name text COLLATE ch03_a.case_insensitive PRIMARY KEY);
INSERT INTO ch03_a.tags_ci VALUES ('PostgreSQL');
