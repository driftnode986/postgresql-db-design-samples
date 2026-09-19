-- パーティションに分けた表に、あとから外部キーを足す。
--
-- 外部キーを普通に足すと、既存の全行を検査するあいだロックを保持する。
-- PostgreSQL 18 からは、パーティションに分けた表にも NOT VALID を付けられる。
-- NOT VALID で足すと既存の行を検査しないので短く済み、
-- 検査は別のコマンドで、あとから実行できる。
--
-- run-as: book_owner
\timing on

-- (1) 検査せずに足す
ALTER TABLE ch13_d.deals
  ADD CONSTRAINT deals_tenant_fk FOREIGN KEY (tenant_id)
  REFERENCES ch13_d.tenants(id) NOT VALID;

-- (2) あとから検査する
ALTER TABLE ch13_d.deals VALIDATE CONSTRAINT deals_tenant_fk;

\timing off

SELECT conname, convalidated
FROM pg_constraint
WHERE conrelid = 'ch13_d.deals'::regclass AND contype = 'f';
