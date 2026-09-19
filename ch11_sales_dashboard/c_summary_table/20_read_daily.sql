-- run-as: book_app
-- 案C: 日別の売上 30 日ぶん。
--
-- 🔴 3 回流して中央値を取る（docs/measurement-rules.yml）。
\timing on

\echo '=== 案C 日別 30 日分（3 回） ==='
EXPLAIN (ANALYZE)
SELECT sales_date, sum(net_yen) AS net_yen
  FROM ch11_c.daily_sales
 WHERE sales_date > (now() AT TIME ZONE 'Asia/Tokyo')::date - 30
 GROUP BY 1 ORDER BY 1;

EXPLAIN (ANALYZE)
SELECT sales_date, sum(net_yen) AS net_yen
  FROM ch11_c.daily_sales
 WHERE sales_date > (now() AT TIME ZONE 'Asia/Tokyo')::date - 30
 GROUP BY 1 ORDER BY 1;

EXPLAIN (ANALYZE)
SELECT sales_date, sum(net_yen) AS net_yen
  FROM ch11_c.daily_sales
 WHERE sales_date > (now() AT TIME ZONE 'Asia/Tokyo')::date - 30
 GROUP BY 1 ORDER BY 1;
