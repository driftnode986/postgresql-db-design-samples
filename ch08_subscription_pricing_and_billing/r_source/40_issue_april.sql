-- run-as: book_owner
-- 2024 年 4 月分の請求を、4 案すべてで発行する。
--
-- 日割りは daterange の共通部分（* 演算子）で出す。
-- 半開区間 [開始, 終了) なので、プランの切り替え日はどちらか一方にだけ入り、
-- 二重に数えることも、1 日抜けることも起きない。
--
-- 🔴 この時点では、まだ料金を改定していない。
--    改定する前の「正しい請求書」を 4 案ぶん作り、あとで改定してから再発行して比べる。
\set m '2024-04-01'
\set mr 'daterange(''2024-04-01'',''2024-05-01'')'
-- 🔴 月の日数をリテラルで書かない。範囲の上端と下端の差で求める。
--    30 と書くと、31 日の月・28 日の月で写経したときに誤った日割りになる。
\set dim '(upper(daterange(''2024-04-01'',''2024-05-01'')) - lower(daterange(''2024-04-01'',''2024-05-01'')))'
\timing on

-- 案A: プランの現在の料金を引く（版が無いので、これしか引けない）
INSERT INTO ch08_a.invoice_lines
  (subscription_id, billed_month, plan_id, charged_days, days_in_month)
SELECT s.id, DATE :'m', s.plan_id,
       upper(s.period * :mr) - lower(s.period * :mr),
       :dim
FROM ch08_a.subscriptions s
WHERE s.period && :mr
ORDER BY s.id;

-- 案B: 料金の版から、その期間の開始時点の額を引いて写す。
-- 据え置きの契約は grandfathered_yen を使い、料金表を引かない
INSERT INTO ch08_b.invoice_lines
  (subscription_id, billed_month, plan_id, plan_name, unit_yen,
   charged_days, days_in_month)
SELECT s.id, DATE :'m', s.plan_id, p.name,
       COALESCE(s.grandfathered_yen, pr.price_yen),
       upper(s.period * :mr) - lower(s.period * :mr),
       :dim
FROM ch08_b.subscriptions s
JOIN ch08_b.plans p ON p.id = s.plan_id
JOIN ch08_b.plan_prices pr
  ON pr.plan_id = s.plan_id
 AND pr.valid @> lower(s.period * :mr)
WHERE s.period && :mr
ORDER BY s.id;

-- 案C: 金額を写さず、plan_id と日数だけを記録する
INSERT INTO ch08_c.invoice_lines
  (subscription_id, billed_month, plan_id, charged_days, days_in_month)
SELECT s.id, DATE :'m', s.plan_id,
       upper(s.period * :mr) - lower(s.period * :mr),
       :dim
FROM ch08_c.subscriptions s
WHERE s.period && :mr
ORDER BY s.id;

-- 案D: 写しと、どの版から引いたかの両方を記録する
--
-- 🔴 priced_on には、引いた版そのものの開始日（lower(pr.valid)）を入れる。
--    「料金表を引いた基準日」を入れると、月初から続く契約が全部同じ日付になり、
--    どの版を使ったかを特定できない（初稿はそうなっていた）。
INSERT INTO ch08_d.invoice_lines
  (subscription_id, billed_month, plan_id, plan_name, unit_yen, priced_on,
   charged_days, days_in_month)
SELECT s.id, DATE :'m', s.plan_id, p.name,
       COALESCE(s.grandfathered_yen, pr.price_yen),
       lower(pr.valid),
       upper(s.period * :mr) - lower(s.period * :mr),
       :dim
FROM ch08_d.subscriptions s
JOIN ch08_d.plans p ON p.id = s.plan_id
JOIN ch08_d.plan_prices pr
  ON pr.plan_id = s.plan_id
 AND pr.valid @> lower(s.period * :mr)
WHERE s.period && :mr
ORDER BY s.id;

\echo '--- 発行した明細の件数 ---'
SELECT (SELECT count(*) FROM ch08_a.invoice_lines) AS a,
       (SELECT count(*) FROM ch08_b.invoice_lines) AS b,
       (SELECT count(*) FROM ch08_c.invoice_lines) AS c,
       (SELECT count(*) FROM ch08_d.invoice_lines) AS d;
