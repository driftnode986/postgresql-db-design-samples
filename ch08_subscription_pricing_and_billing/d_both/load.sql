-- 元データ（ch08_r）から案D へ写す。案C と同じ制約が働く。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch08_r.src_sub_period) = 0 THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

-- 案C と同じく、参照されている plan_prices は subscriptions と同じ文で空にする
TRUNCATE ch08_d.invoice_lines, ch08_d.subscriptions, ch08_d.plan_prices,
         ch08_d.plans RESTART IDENTITY;

INSERT INTO ch08_d.plans (code, name)
SELECT code, name FROM ch08_r.src_plan ORDER BY id;

INSERT INTO ch08_d.plan_prices (plan_id, valid, price_yen)
SELECT plan_id, valid, price_yen FROM ch08_r.src_price ORDER BY id;

INSERT INTO ch08_d.subscriptions (customer_id, plan_id, period, grandfathered_yen)
SELECT s.customer_id, sp.plan_id, sp.period, sp.grandfathered_yen
FROM ch08_r.src_sub_period sp
JOIN ch08_r.src_subscription s ON s.id = sp.subscription_id
ORDER BY sp.id;

ANALYZE ch08_d.plans;
ANALYZE ch08_d.plan_prices;
ANALYZE ch08_d.subscriptions;
