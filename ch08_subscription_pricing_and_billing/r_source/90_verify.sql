-- 第8章の検査。返す行の先頭列がすべて 0 なら正常。
--
-- 🔴 「改定しても過去の請求書が変わらない」は、速さではなく正しさの要件である。
--    この章の主張は、この検査が 0 を返すことで裏づけられる。
\echo '--- 1. 改定後に金額が変わった明細の数（案B・C・D は 0 が正常。案A は除く）---'
WITH after_amounts AS (
  SELECT 'B' AS plan_kind, l.subscription_id, l.subtotal_yen AS amount_yen
  FROM ch08_b.invoice_lines l
  UNION ALL
  SELECT 'C', l.subscription_id,
         (pr.price_yen * l.charged_days / l.days_in_month)::bigint
  FROM ch08_c.invoice_lines l
  JOIN ch08_c.subscriptions s ON s.id = l.subscription_id
  JOIN ch08_c.plan_prices pr
    ON pr.plan_id = l.plan_id
   AND pr.valid @> lower(s.period * daterange('2024-04-01','2024-05-01'))
  UNION ALL
  SELECT 'D', l.subscription_id, l.subtotal_yen FROM ch08_d.invoice_lines l
)
SELECT count(*) AS changed_lines
FROM ch08_r.before_amounts b
JOIN after_amounts a
  ON a.plan_kind = b.plan_kind AND a.subscription_id = b.subscription_id
WHERE a.amount_yen <> b.amount_yen;

\echo '--- 2. 料金の版に期間の重なりがある組（0 が正常）---'
-- 🔴 この検査は、案B に対しては常に 0 を返す。EXCLUDE 制約が重なる行の INSERT を
--    はじくので、違反の状態を作れないからである（実測: 制約違反でエラーになる）。
--    つまりこの 0 は「制約が効いている」ことの確認であって、検査器が働いた証拠ではない。
--    検査の式そのものが重なりを見つけられることは、制約の無い一時表で別に確かめてある。
SELECT count(*) AS overlapping_pairs
FROM ch08_b.plan_prices a
JOIN ch08_b.plan_prices b
  ON a.plan_id = b.plan_id AND a.id < b.id AND a.valid && b.valid;

\echo '--- 3. 料金の版に、契約の期間を覆えないすき間があるプラン（0 が正常）---'
-- 契約が存在する全期間を、料金の版の合併が覆っているか。
-- 案C・案D は期間つき外部キーが同じことを常に検査しているので、ここでは案B を見る。
SELECT count(*) AS uncovered_subscriptions
FROM ch08_b.subscriptions s
WHERE NOT (
  SELECT COALESCE(range_agg(pr.valid), '{}'::datemultirange)
  FROM ch08_b.plan_prices pr WHERE pr.plan_id = s.plan_id
) @> datemultirange(
      daterange(lower(s.period),
                COALESCE(upper(s.period), DATE '2030-01-01')));

\echo '--- 4. 日割りの日数が、その月の日数を超えている明細（0 が正常）---'
SELECT count(*) AS bad_days FROM ch08_b.invoice_lines
WHERE charged_days > days_in_month OR charged_days <= 0;

\echo '--- 5. 案C が再計算した額と、案B が写した額の食い違い（据え置きのぶんだけ出る）---'
-- 🔴 この検査は 0 にならない。0 にならないことが正しい。
--    案C は据え置きの額を持てない（subscriptions に grandfathered_yen が無い）ので、
--    料金表から引き直すと、据え置きの契約はその時点の版の額になる。
--
--    検査 1（改定の前後で動かないか）は、案C についてはこれを検出できない。
--    改定の前も後も同じ「据え置きを無視した式」で計算しているため、
--    誤った値どうしを引き算して 0 になるからである。
--    「動かないこと」と「正しいこと」は別である。
WITH c AS (
  SELECT l.subscription_id,
         (pr.price_yen * l.charged_days / l.days_in_month)::bigint AS amt
  FROM ch08_c.invoice_lines l
  JOIN ch08_c.subscriptions s ON s.id = l.subscription_id
  JOIN ch08_c.plan_prices pr
    ON pr.plan_id = l.plan_id
   AND pr.valid @> lower(s.period * daterange('2024-04-01','2024-05-01'))
),
b AS (
  SELECT l.subscription_id, l.subtotal_yen AS amt, s.grandfathered_yen
  FROM ch08_b.invoice_lines l
  JOIN ch08_b.subscriptions s ON s.id = l.subscription_id
)
SELECT count(*) FILTER (WHERE c.amt <> b.amt
                          AND b.grandfathered_yen IS NULL) AS unexplained_diff,
       count(*) FILTER (WHERE c.amt <> b.amt)              AS c_differs_from_b,
       count(*) FILTER (WHERE c.amt <> b.amt
                          AND b.grandfathered_yen IS NOT NULL) AS of_which_grandfathered
FROM b JOIN c USING (subscription_id);

\echo '--- 6. 同じ契約・同じ月の明細が、案によって件数が違う（0 が正常）---'
SELECT count(*) AS count_mismatch FROM (
  SELECT (SELECT count(*) FROM ch08_a.invoice_lines) a,
         (SELECT count(*) FROM ch08_b.invoice_lines) b,
         (SELECT count(*) FROM ch08_c.invoice_lines) c,
         (SELECT count(*) FROM ch08_d.invoice_lines) d
) t WHERE a <> b OR b <> c OR c <> d;
