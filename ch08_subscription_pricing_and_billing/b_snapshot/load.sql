-- 元データ（ch08_r）から案B へ写す。
-- 案B は料金の版をすべて持てるので、元データの src_price をそのまま写す。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch08_r.src_sub_period) = 0 THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch08_b.invoice_lines RESTART IDENTITY;
TRUNCATE ch08_b.subscriptions RESTART IDENTITY CASCADE;
TRUNCATE ch08_b.plan_prices RESTART IDENTITY CASCADE;
TRUNCATE ch08_b.plans RESTART IDENTITY CASCADE;

INSERT INTO ch08_b.plans (code, name)
SELECT code, name FROM ch08_r.src_plan ORDER BY id;

INSERT INTO ch08_b.plan_prices (plan_id, valid, price_yen)
SELECT plan_id, valid, price_yen FROM ch08_r.src_price ORDER BY id;

INSERT INTO ch08_b.subscriptions (customer_id, plan_id, period, grandfathered_yen)
SELECT s.customer_id, sp.plan_id, sp.period, sp.grandfathered_yen
FROM ch08_r.src_sub_period sp
JOIN ch08_r.src_subscription s ON s.id = sp.subscription_id
ORDER BY sp.id;

ANALYZE ch08_b.plans;
ANALYZE ch08_b.plan_prices;
ANALYZE ch08_b.subscriptions;
