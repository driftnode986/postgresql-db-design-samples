-- 4 案が同じ中身を持つことを検査する。全行の先頭列が 0 になる。
--
-- 🔴 案C は表が会社ごとに分かれているので、集めてから比べる。
-- 🔴 検査は book_owner で流す。book_app で流すと案B の RLS で 0 行に見え、
--    違いがあっても通ってしまう。
--
-- run-as: book_owner
-- standalone

-- 案B のポリシーを一時的に迂回するため、ここでは所有者の NO FORCE を使う。
ALTER TABLE ch13_b.deals     NO FORCE ROW LEVEL SECURITY;
ALTER TABLE ch13_b.customers NO FORCE ROW LEVEL SECURITY;

-- (1) 案A 対 案B
SELECT count(*) AS a_vs_b_diff_must_be_zero FROM (
  (SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_a.deals
   EXCEPT
   SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_b.deals)
  UNION ALL
  (SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_b.deals
   EXCEPT
   SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_a.deals)
) d;

-- (2) 案A 対 案D
SELECT count(*) AS a_vs_d_diff_must_be_zero FROM (
  (SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_a.deals
   EXCEPT
   SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_d.deals)
  UNION ALL
  (SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_d.deals
   EXCEPT
   SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_a.deals)
) d;

-- (3) 案A 対 案C（テナント 2 社を抜き取って比べる。全スキーマを UNION すると
--     1,000 本の問い合わせになるため、代表を見る）
SELECT count(*) AS a_vs_c_t0050_diff_must_be_zero FROM (
  (SELECT id, customer_id, title, amount, created_at FROM ch13_a.deals WHERE tenant_id = 50
   EXCEPT
   SELECT id, customer_id, title, amount, created_at FROM ch13_c_t0050.deals)
  UNION ALL
  (SELECT id, customer_id, title, amount, created_at FROM ch13_c_t0050.deals
   EXCEPT
   SELECT id, customer_id, title, amount, created_at FROM ch13_a.deals WHERE tenant_id = 50)
) d;

-- (4) 案C の全スキーマの合計行数が、案A の全行数と一致すること。
--     スキーマの数だけ問い合わせを組み立てて合計する。
DO $$
DECLARE
  t record; total bigint := 0; cnt bigint; expected bigint;
BEGIN
  FOR t IN SELECT schema_name FROM ch13_c.tenants ORDER BY id LOOP
    EXECUTE format('SELECT count(*) FROM %I.deals', t.schema_name) INTO cnt;
    total := total + cnt;
  END LOOP;
  SELECT count(*) INTO expected FROM ch13_a.deals;
  IF total <> expected THEN
    RAISE EXCEPTION '案C の合計 % が案A の % と一致しません', total, expected;
  END IF;
  RAISE NOTICE 'c_total_diff_must_be_zero = 0 (案C 合計 % 行)', total;
END $$;

ALTER TABLE ch13_b.deals     FORCE ROW LEVEL SECURITY;
ALTER TABLE ch13_b.customers FORCE ROW LEVEL SECURITY;
