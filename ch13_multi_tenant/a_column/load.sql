-- 案A に元データを写す。
--
-- 🔴 元データが空なら、何も消す前にエラーで止める。
--    空のまま写すと、全案が空になり、検査が「一致」で通ってしまう。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch13_r.src_deal) = 0 THEN
    RAISE EXCEPTION '元データ ch13_r.src_deal が空です。先に r_source/ を実行してください';
  END IF;
END $$;

TRUNCATE ch13_a.deals, ch13_a.customers, ch13_a.tenants RESTART IDENTITY CASCADE;

INSERT INTO ch13_a.tenants (id, name, status)
SELECT id, name, status FROM ch13_r.src_tenant ORDER BY id;

INSERT INTO ch13_a.customers (tenant_id, id, email, name)
SELECT tenant_id, id, email, name FROM ch13_r.src_customer ORDER BY tenant_id, id;

INSERT INTO ch13_a.deals (tenant_id, id, customer_id, title, amount, created_at)
SELECT tenant_id, id, customer_id, title, amount, created_at
FROM ch13_r.src_deal ORDER BY tenant_id, id;

-- 🔴 インデックスはデータを入れてから作る（規約。付けたまま入れると充填率が変わる）。
CREATE INDEX deals_tenant_created_a ON ch13_a.deals (tenant_id, created_at DESC);
CREATE INDEX customers_tenant_email_a ON ch13_a.customers (tenant_id, email);

ANALYZE ch13_a.tenants, ch13_a.customers, ch13_a.deals;
