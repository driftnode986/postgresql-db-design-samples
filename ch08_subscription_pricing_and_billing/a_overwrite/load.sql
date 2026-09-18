-- 元データ（ch08_r）から案A へ写す。
--
-- 案A のプランは料金を 1 つしか持てないので、版のうち「いま有効なもの」だけを写す。
-- 過去の版は、この案には置き場所が無い。ここで情報が落ちることが案A の性質である。
--
-- 🔴 元データが空なら、何も消す前にエラーで止める。
--    load を先に流して「全案が空のまま全件 OK」になる事故を防ぐ（第2章で実際に起きた）。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch08_r.src_sub_period) = 0 THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch08_a.invoice_lines RESTART IDENTITY;
TRUNCATE ch08_a.subscriptions RESTART IDENTITY CASCADE;
TRUNCATE ch08_a.plans RESTART IDENTITY CASCADE;

INSERT INTO ch08_a.plans (code, name, price_yen)
SELECT p.code, p.name,
       -- いま有効な版の額。案A はこれしか持てない
       (SELECT pr.price_yen FROM ch08_r.src_price pr
        WHERE pr.plan_id = p.id AND upper_inf(pr.valid))
FROM ch08_r.src_plan p
ORDER BY p.id;

INSERT INTO ch08_a.subscriptions (customer_id, plan_id, period)
SELECT s.customer_id, sp.plan_id, sp.period
FROM ch08_r.src_sub_period sp
JOIN ch08_r.src_subscription s ON s.id = sp.subscription_id
ORDER BY sp.id;

ANALYZE ch08_a.plans;
ANALYZE ch08_a.subscriptions;
