-- 元データ（ch08_r）から案C へ写す。
--
-- 🔴 ここで期間つき外部キーが働く。契約の期間が料金の版で覆われていなければ、
--    この INSERT が 23503 で落ちる。案B の同じ INSERT は何も言わずに通る。
--    「同じデータを入れて、案C だけが止まる」ことが、この案の検査の強さそのものである。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch08_r.src_sub_period) = 0 THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

-- 🔴 plan_prices は subscriptions から期間つき外部キーで参照されている。
--    参照している側を空にした後でも、TRUNCATE は「参照されている」ことを理由に拒否する。
--    同じ文で両方を指定する（CASCADE を使うと、思わぬ表まで巻き込む）。
TRUNCATE ch08_c.invoice_lines, ch08_c.subscriptions, ch08_c.plan_prices,
         ch08_c.plans RESTART IDENTITY;

INSERT INTO ch08_c.plans (code, name)
SELECT code, name FROM ch08_r.src_plan ORDER BY id;

INSERT INTO ch08_c.plan_prices (plan_id, valid, price_yen)
SELECT plan_id, valid, price_yen FROM ch08_r.src_price ORDER BY id;

INSERT INTO ch08_c.subscriptions (customer_id, plan_id, period)
SELECT s.customer_id, sp.plan_id, sp.period
FROM ch08_r.src_sub_period sp
JOIN ch08_r.src_subscription s ON s.id = sp.subscription_id
ORDER BY sp.id;

ANALYZE ch08_c.plans;
ANALYZE ch08_c.plan_prices;
ANALYZE ch08_c.subscriptions;
