-- run-as: book_owner
-- 料金を改定してから、同じ 2024 年 4 月分を「再発行」して、改定前の金額と比べる。
--
-- 章の中心にある測定である。速さではなく、金額が変わるかどうかを測る。
--
-- 改定のしかたは案ごとに違う。
--   案A … プランの行を上書きする（版が無いので、これしかできない）
--   案B・C・D … 今の版を 2024-05-01 で閉じ、新しい版を足す（過去の版は変えない）
--
-- 🔴 どの案も「2024 年 5 月から値上げする」という同じ業務上の操作をしている。
--    4 月分の請求書は、どの案でも変わらないのが正しい。
\set m '2024-04-01'
\set mr 'daterange(''2024-04-01'',''2024-05-01'')'
\timing on

-- 改定前の金額を控えておく（あとで差額を出すため）
DROP TABLE IF EXISTS ch08_r.before_amounts;
CREATE TABLE ch08_r.before_amounts AS
SELECT 'A' AS plan_kind, l.subscription_id,
       (p.price_yen * l.charged_days / l.days_in_month)::bigint AS amount_yen
FROM ch08_a.invoice_lines l JOIN ch08_a.plans p ON p.id = l.plan_id
UNION ALL
SELECT 'B', l.subscription_id, l.subtotal_yen FROM ch08_b.invoice_lines l
UNION ALL
SELECT 'C', l.subscription_id,
       (pr.price_yen * l.charged_days / l.days_in_month)::bigint
FROM ch08_c.invoice_lines l
JOIN ch08_c.subscriptions s ON s.id = l.subscription_id
JOIN ch08_c.plan_prices pr
  ON pr.plan_id = l.plan_id AND pr.valid @> lower(s.period * :mr)
UNION ALL
SELECT 'D', l.subscription_id, l.subtotal_yen FROM ch08_d.invoice_lines l;

-- ここで値上げする（2024-05-01 から 20% 値上げ）
UPDATE ch08_a.plans SET price_yen = (price_yen * 1.2)::int;

-- 案B・C・D: 今の版（上端なし）を 2024-05-01 で閉じ、新しい版を足す
UPDATE ch08_b.plan_prices SET valid = daterange(lower(valid), DATE '2024-05-01')
WHERE upper_inf(valid);
INSERT INTO ch08_b.plan_prices (plan_id, valid, price_yen)
SELECT plan_id, daterange(DATE '2024-05-01', NULL), (price_yen * 1.2)::int
FROM ch08_b.plan_prices WHERE upper(valid) = DATE '2024-05-01';

-- 🔴 案C・案D は、案B と同じ 2 文をそのまま流せない。
--    契約が上端なしの期間（[開始, ∞)）で今の版を参照しているので、
--    版を 2024-05-01 で閉じた時点で「5 月以降を覆う版が無い」状態になり、
--    期間つき外部キーが UPDATE を拒否する。
--    順序を入れ替えて先に新しい版を足すと、今度は期間が重なって主キーに弾かれる。
--    どちらの順序でも、途中の状態が制約に触れる。
--
--    制約の検査をトランザクションの終わりまで待たせる。
--    これができるのは、表を作るときに DEFERRABLE を付けておいた場合だけである。
BEGIN;
SET CONSTRAINTS ALL DEFERRED;
UPDATE ch08_c.plan_prices SET valid = daterange(lower(valid), DATE '2024-05-01')
WHERE upper_inf(valid);
INSERT INTO ch08_c.plan_prices (plan_id, valid, price_yen)
SELECT plan_id, daterange(DATE '2024-05-01', NULL), (price_yen * 1.2)::int
FROM ch08_c.plan_prices WHERE upper(valid) = DATE '2024-05-01';
COMMIT;

BEGIN;
SET CONSTRAINTS ALL DEFERRED;
UPDATE ch08_d.plan_prices SET valid = daterange(lower(valid), DATE '2024-05-01')
WHERE upper_inf(valid);
INSERT INTO ch08_d.plan_prices (plan_id, valid, price_yen)
SELECT plan_id, daterange(DATE '2024-05-01', NULL), (price_yen * 1.2)::int
FROM ch08_d.plan_prices WHERE upper(valid) = DATE '2024-05-01';
COMMIT;

\echo '--- 改定後に、同じ 4 月分を再発行したときの金額との差額 ---'
WITH after_amounts AS (
  SELECT 'A' AS plan_kind, l.subscription_id,
         (p.price_yen * l.charged_days / l.days_in_month)::bigint AS amount_yen
  FROM ch08_a.invoice_lines l JOIN ch08_a.plans p ON p.id = l.plan_id
  UNION ALL
  SELECT 'B', l.subscription_id, l.subtotal_yen FROM ch08_b.invoice_lines l
  UNION ALL
  SELECT 'C', l.subscription_id,
         (pr.price_yen * l.charged_days / l.days_in_month)::bigint
  FROM ch08_c.invoice_lines l
  JOIN ch08_c.subscriptions s ON s.id = l.subscription_id
  JOIN ch08_c.plan_prices pr
    ON pr.plan_id = l.plan_id AND pr.valid @> lower(s.period * :mr)
  UNION ALL
  SELECT 'D', l.subscription_id, l.subtotal_yen FROM ch08_d.invoice_lines l
)
SELECT b.plan_kind,
       count(*) FILTER (WHERE a.amount_yen <> b.amount_yen) AS changed_lines,
       sum(a.amount_yen - b.amount_yen)                     AS diff_yen
FROM ch08_r.before_amounts b
JOIN after_amounts a
  ON a.plan_kind = b.plan_kind AND a.subscription_id = b.subscription_id
GROUP BY b.plan_kind ORDER BY b.plan_kind;
