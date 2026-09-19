-- run-as: book_app
-- 案D: 日別の売上 30 日ぶん。
--
-- 🔴 3 回流して中央値を取る（docs/measurement-rules.yml）。
\timing on

\echo '=== 案D 日別 30 日分（3 回） ==='
EXPLAIN (ANALYZE)
SELECT sales_date, sum(net_yen) AS net_yen
  FROM ch11_d.daily_sales_final
 WHERE sales_date > (now() AT TIME ZONE 'Asia/Tokyo')::date - 30
 GROUP BY 1
UNION ALL
SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date,
       sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0)
  FROM ch11_d.order_lines l
  LEFT JOIN ch11_d.returns r ON r.order_line_id = l.id
 WHERE (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date
     = (now() AT TIME ZONE 'Asia/Tokyo')::date
 GROUP BY 1
 ORDER BY 1;

EXPLAIN (ANALYZE)
SELECT sales_date, sum(net_yen) AS net_yen
  FROM ch11_d.daily_sales_final
 WHERE sales_date > (now() AT TIME ZONE 'Asia/Tokyo')::date - 30
 GROUP BY 1
UNION ALL
SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date,
       sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0)
  FROM ch11_d.order_lines l
  LEFT JOIN ch11_d.returns r ON r.order_line_id = l.id
 WHERE (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date
     = (now() AT TIME ZONE 'Asia/Tokyo')::date
 GROUP BY 1
 ORDER BY 1;

EXPLAIN (ANALYZE)
SELECT sales_date, sum(net_yen) AS net_yen
  FROM ch11_d.daily_sales_final
 WHERE sales_date > (now() AT TIME ZONE 'Asia/Tokyo')::date - 30
 GROUP BY 1
UNION ALL
SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date,
       sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0)
  FROM ch11_d.order_lines l
  LEFT JOIN ch11_d.returns r ON r.order_line_id = l.id
 WHERE (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date
     = (now() AT TIME ZONE 'Asia/Tokyo')::date
 GROUP BY 1
 ORDER BY 1;
