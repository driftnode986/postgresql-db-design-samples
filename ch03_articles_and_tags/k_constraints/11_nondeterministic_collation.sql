-- 方法 1: 大文字小文字を区別しない照合順序を作り、その照合順序で一意制約を張る
CREATE COLLATION IF NOT EXISTS ch03_k.case_insensitive
  (provider = icu, locale = 'und-u-ks-level2', deterministic = false);
DROP TABLE IF EXISTS ch03_k.tags_ci;
CREATE TABLE ch03_k.tags_ci (
  name text COLLATE ch03_k.case_insensitive PRIMARY KEY);
INSERT INTO ch03_k.tags_ci VALUES ('PostgreSQL');
