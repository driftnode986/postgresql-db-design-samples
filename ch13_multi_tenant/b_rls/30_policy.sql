-- run-as: book_owner
-- 案B のポリシーを付ける。
--
-- ENABLE だけでは、表を作った本人（所有者）には適用されない。
-- FORCE を付けて、所有者にも適用させる。
ALTER TABLE ch13_b.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ch13_b.deals     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ch13_b.customers FORCE  ROW LEVEL SECURITY;
ALTER TABLE ch13_b.deals     FORCE  ROW LEVEL SECURITY;

-- USING は読み取りの条件。書き込みの条件（WITH CHECK）を省くと、
-- USING が暗黙の WITH CHECK として使われる。
CREATE POLICY tenant_isolation ON ch13_b.customers
  USING (tenant_id = current_setting('app.tenant_id')::int);

CREATE POLICY tenant_isolation ON ch13_b.deals
  USING (tenant_id = current_setting('app.tenant_id')::int);

-- 測定用のロールに読み書きを許す。ポリシーは GRANT とは別の層なので、
-- GRANT しただけでは他社の行は見えない。
GRANT SELECT, INSERT, UPDATE, DELETE ON ch13_b.customers, ch13_b.deals TO book_app;
GRANT SELECT ON ch13_b.tenants TO book_app;

SELECT relname,
       relrowsecurity  AS enabled,
       relforcerowsecurity AS forced
FROM pg_class
WHERE oid IN ('ch13_b.customers'::regclass, 'ch13_b.deals'::regclass)
ORDER BY relname;
