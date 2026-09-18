-- 変更の手数（案C）: 衣料に属性「原産国」を足す → 必須にする → 絞り込めるようにする。
-- 案A と同じ形の文を、衣料の子テーブルだけに実行する。ロックを取るのも衣料の子テーブルだけ
\timing on
SELECT pg_relation_filenode('ch02_c.apparel') AS filenode_before \gset
BEGIN;
ALTER TABLE ch02_c.apparel ADD COLUMN origin text DEFAULT 'JP';
SELECT relation::regclass, mode FROM pg_locks
WHERE relation IN ('ch02_c.products'::regclass, 'ch02_c.apparel'::regclass,
                   'ch02_c.appliance'::regclass, 'ch02_c.book'::regclass)
  AND pid = pg_backend_pid();
SELECT pg_relation_filenode('ch02_c.apparel') = :filenode_before
       AS not_rewritten;
COMMIT;

BEGIN;
ALTER TABLE ch02_c.apparel
  ADD CONSTRAINT apparel_origin_nn NOT NULL origin NOT VALID;
COMMIT;
BEGIN;
ALTER TABLE ch02_c.apparel VALIDATE CONSTRAINT apparel_origin_nn;
SELECT relation::regclass, mode FROM pg_locks
WHERE relation IN ('ch02_c.products'::regclass, 'ch02_c.apparel'::regclass,
                   'ch02_c.appliance'::regclass, 'ch02_c.book'::regclass)
  AND pid = pg_backend_pid();
COMMIT;

CREATE INDEX apparel_origin ON ch02_c.apparel (origin);

-- 元に戻す
DROP INDEX ch02_c.apparel_origin;
ALTER TABLE ch02_c.apparel DROP COLUMN origin;
