-- 開始日が違うだけの、期間の重なる 2 行。UNIQUE は通してしまう。
TRUNCATE ch08_x.plan_prices RESTART IDENTITY;

INSERT INTO ch08_x.plan_prices (plan_id, valid_from, valid_to, price_yen)
VALUES (1, DATE '2024-01-01', DATE '2024-07-01', 1000),
       (1, DATE '2024-03-01', DATE '2024-09-01', 1200);

\echo '--- 2024-04-01 の時点で有効な料金が何行あるか（1 行が正しい）---'
SELECT count(*) AS rows_matched
FROM ch08_x.plan_prices
WHERE plan_id = 1
  AND valid_from <= DATE '2024-04-01'
  AND (valid_to IS NULL OR valid_to > DATE '2024-04-01');
