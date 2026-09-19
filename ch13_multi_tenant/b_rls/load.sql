-- 案B に元データを写す。案A と同じ順・同じインデックスにする。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch13_r.src_deal) = 0 THEN
    RAISE EXCEPTION '元データ ch13_r.src_deal が空です。先に r_source/ を実行してください';
  END IF;
END $$;

TRUNCATE ch13_b.deals, ch13_b.customers, ch13_b.tenants RESTART IDENTITY CASCADE;

INSERT INTO ch13_b.tenants (id, name, status)
SELECT id, name, status FROM ch13_r.src_tenant ORDER BY id;

INSERT INTO ch13_b.customers (tenant_id, id, email, name)
SELECT tenant_id, id, email, name FROM ch13_r.src_customer ORDER BY tenant_id, id;

INSERT INTO ch13_b.deals (tenant_id, id, customer_id, title, amount, created_at)
SELECT tenant_id, id, customer_id, title, amount, created_at
FROM ch13_r.src_deal ORDER BY tenant_id, id;

CREATE INDEX deals_tenant_created_b ON ch13_b.deals (tenant_id, created_at DESC);
CREATE INDEX customers_tenant_email_b ON ch13_b.customers (tenant_id, email);

ANALYZE ch13_b.tenants, ch13_b.customers, ch13_b.deals;
