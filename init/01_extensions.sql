-- 01_extensions.sql: 本書で使う拡張
--
-- 3つとも postgres:18.6 のイメージに同梱されている。
-- 置き場所は public。btree_gist は専用スキーマに置いても WITHOUT OVERLAPS と EXCLUDE で使えるが、
-- ltree は search_path に無いと型も演算子も見つからず、OPERATOR(スキーマ名.<@) と書くことになる。
-- pgstattuple と pg_stat_statements の作成にはスーパーユーザー権限が必要なので、
-- 初期化の段階（book_admin）で作る。

CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS pgstattuple;

-- pgstattuple の関数は既定では pg_stat_scan_tables ロールにだけ実行が許可される
-- book_owner には付けない（自分のテーブルでも実行できない）。サイズと密度は book_app で採る
GRANT pg_stat_scan_tables TO book_app;
