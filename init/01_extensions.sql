-- 01_extensions.sql: 本書で使う拡張
--
-- 3つとも postgres:18.6 のイメージに同梱されている。
-- 置き場所は public。専用スキーマに置いた場合に WITHOUT OVERLAPS が btree_gist の
-- 演算子クラスを解決できるかは未確認のため、確かめるまでは public に置く（第1章で確定する）。
-- pgstattuple と pg_stat_statements の作成にはスーパーユーザー権限が必要なので、
-- 初期化の段階（book_admin）で作る。

CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS pgstattuple;

-- pgstattuple の関数は既定では pg_stat_scan_tables ロールにだけ実行が許可される
GRANT pg_stat_scan_tables TO book_app;
