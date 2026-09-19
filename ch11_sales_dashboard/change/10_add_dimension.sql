-- run-as: book_owner
-- 変更シナリオ: 集計の軸を 1 つ足す（地域別）。
--
-- 🔴 「あとで変えるのが大変な点」を実測する。記録するのは 4 つ:
--    SQL 文の数 / テーブルの書き換えの有無 / 取るロック / 所要時間。
\timing on

\echo '=== 変更前のファイルノード（書き換えが起きたかを見る） ==='
SELECT pg_relation_filenode('ch11_c.daily_sales') AS filenode_before;

\echo '=== (1) 案C: 集計テーブルに列を足す ==='
-- 既定値が無いので、18 ではテーブルを書き換えない（メタデータだけ）
ALTER TABLE ch11_c.daily_sales ADD COLUMN region_id int;

\echo '=== 列を足した直後のファイルノード ==='
SELECT pg_relation_filenode('ch11_c.daily_sales') AS filenode_after_add;

\echo '=== (2) 取るロック（トランザクションの中で見る） ==='
BEGIN;
ALTER TABLE ch11_c.daily_sales ADD COLUMN region_id2 int;
SELECT c.relname, l.mode
  FROM pg_locks l JOIN pg_class c ON c.oid = l.relation
  JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'ch11_c' AND c.relname = 'daily_sales'
 ORDER BY l.mode;
ROLLBACK;

\echo '=== (3) 🔴 本当の問題は、粒度が変わると過去のぶんを作り直すこと ==='
-- 地域別の値は、既存の集計行からは復元できない。
-- 日別 × 商品別に畳んだ時点で、地域の情報は失われているためである。
-- したがって元データから全部作り直すことになる。
SELECT count(*) AS rows_to_rebuild FROM ch11_c.daily_sales;

\echo '=== (4) 主キーを張り替える（粒度を変えるとはこういうこと） ==='
-- 日別 × 商品別 → 日別 × 商品別 × 地域別
ALTER TABLE ch11_c.daily_sales DROP CONSTRAINT daily_sales_pkey;
UPDATE ch11_c.daily_sales SET region_id = 1 WHERE region_id IS NULL;
ALTER TABLE ch11_c.daily_sales ALTER COLUMN region_id SET NOT NULL;
ALTER TABLE ch11_c.daily_sales
  ADD CONSTRAINT daily_sales_pkey PRIMARY KEY (sales_date, product_id, region_id);

\echo '=== 張り替えた後のファイルノード（UPDATE で全行が書き換わる） ==='
SELECT pg_relation_filenode('ch11_c.daily_sales') AS filenode_after_repk;

\echo '=== 後片付け（次の実行のために元に戻す） ==='
-- 🔴 region_id2 は ROLLBACK したトランザクションの中で足したので、
--    ここには存在しない。DROP しようとするとエラーになる（実際に踏んだ）。
ALTER TABLE ch11_c.daily_sales DROP CONSTRAINT daily_sales_pkey;
ALTER TABLE ch11_c.daily_sales DROP COLUMN region_id;
ALTER TABLE ch11_c.daily_sales
  ADD CONSTRAINT daily_sales_pkey PRIMARY KEY (sales_date, product_id);
