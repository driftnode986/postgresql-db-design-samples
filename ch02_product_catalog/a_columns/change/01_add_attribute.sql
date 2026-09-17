-- 変更の手数（案A）: 属性「原産国」を足す → 必須にする → 絞り込めるようにする。
-- 文の数、テーブルの書き換えの有無（ファイル番号が変わるか）、取るロック、所要時間を記録する。
-- 文ごとに取るロックを分けて見るために、手順ごとにトランザクションを確定し、最後に元へ戻す
\timing on
SELECT pg_relation_filenode('ch02_a.products') AS filenode_before \gset
BEGIN;

-- 1. 属性を足す。固定の既定値なら、既存の行を書き換えない
ALTER TABLE ch02_a.products ADD COLUMN origin text DEFAULT 'JP';
SELECT mode FROM pg_locks
WHERE relation = 'ch02_a.products'::regclass AND pid = pg_backend_pid();
SELECT pg_relation_filenode('ch02_a.products') = :filenode_before AS not_rewritten;
SELECT count(*) FILTER (WHERE origin = 'JP') AS rows_with_default FROM ch02_a.products;
COMMIT;

-- 2. 必須にする。NOT VALID で制約だけを先に足し、既存の行の検査は VALIDATE で別に行う。
--    取るロックを分けて見るために、トランザクションを分ける
BEGIN;
ALTER TABLE ch02_a.products ADD CONSTRAINT products_origin_nn NOT NULL origin NOT VALID;
SELECT mode FROM pg_locks
WHERE relation = 'ch02_a.products'::regclass AND pid = pg_backend_pid();
COMMIT;
BEGIN;
ALTER TABLE ch02_a.products VALIDATE CONSTRAINT products_origin_nn;
SELECT mode FROM pg_locks
WHERE relation = 'ch02_a.products'::regclass AND pid = pg_backend_pid();
COMMIT;

-- 3. 絞り込めるようにする
CREATE INDEX products_origin_created ON ch02_a.products (origin, created_at DESC);

-- 元に戻す。消した列の定義はテーブルに残るので、測定を続けるときは load.sql で入れ直す
DROP INDEX ch02_a.products_origin_created;
ALTER TABLE ch02_a.products DROP COLUMN origin;
