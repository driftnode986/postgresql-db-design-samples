-- run-as: book_app
-- 案A: 画面を開くたびに明細から数える。日別の売上 30 日ぶん。
--
-- 🔴 3 回流して中央値を取る（docs/measurement-rules.yml）。
\timing on

\echo '=== 案A 日別 30 日分（3 回） ==='
EXPLAIN (ANALYZE)
SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS sales_date,
       sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS net_yen
  FROM ch11_a.order_lines l
  LEFT JOIN ch11_a.returns r ON r.order_line_id = l.id
 WHERE (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date
       > (now() AT TIME ZONE 'Asia/Tokyo')::date - 30
 GROUP BY 1 ORDER BY 1;

EXPLAIN (ANALYZE)
SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS sales_date,
       sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS net_yen
  FROM ch11_a.order_lines l
  LEFT JOIN ch11_a.returns r ON r.order_line_id = l.id
 WHERE (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date
       > (now() AT TIME ZONE 'Asia/Tokyo')::date - 30
 GROUP BY 1 ORDER BY 1;

EXPLAIN (ANALYZE)
SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS sales_date,
       sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS net_yen
  FROM ch11_a.order_lines l
  LEFT JOIN ch11_a.returns r ON r.order_line_id = l.id
 WHERE (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date
       > (now() AT TIME ZONE 'Asia/Tokyo')::date - 30
 GROUP BY 1 ORDER BY 1;
