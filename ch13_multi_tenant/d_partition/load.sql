-- 案D に元データを写す。案A・案B と同じ順・同じインデックス。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch13_r.src_deal) = 0 THEN
    RAISE EXCEPTION '元データ ch13_r.src_deal が空です。先に r_source/ を実行してください';
  END IF;
END $$;

TRUNCATE ch13_d.deals, ch13_d.tenants RESTART IDENTITY CASCADE;

INSERT INTO ch13_d.tenants (id, name, status)
SELECT id, name, status FROM ch13_r.src_tenant ORDER BY id;

INSERT INTO ch13_d.deals (tenant_id, id, customer_id, title, amount, created_at)
SELECT tenant_id, id, customer_id, title, amount, created_at
FROM ch13_r.src_deal ORDER BY tenant_id, id;

CREATE INDEX deals_tenant_created_d ON ch13_d.deals (tenant_id, created_at DESC);

ANALYZE ch13_d.tenants, ch13_d.deals;

-- パーティションごとの行数
SELECT c.relname AS partition,
       (SELECT count(*) FROM ch13_d.deals d
         WHERE (c.relname = 'deals_t1' AND d.tenant_id = 1)
            OR (c.relname = 'deals_rest' AND d.tenant_id <> 1)) AS rows
FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
WHERE i.inhparent = 'ch13_d.deals'::regclass
ORDER BY c.relname;
