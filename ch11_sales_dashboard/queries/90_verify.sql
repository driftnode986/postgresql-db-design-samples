-- 4 案の集計が、元データから数え直した値と一致することを確かめる。比較の前提である。
--
-- 🔴 返す全行の先頭列が 0 になるように書く（検証スクリプトが 0 でない行を FAIL にする）。
-- 🔴 検査が 0 を返すことは正しさの証明ではない（第8章 C1）。
--    同じ誤りを両側に含んだ比較はいつでも 0 を返すので、
--    「比べる対象が空でないこと」も同時に検査する。
--    さらに、この章では「わざとズラして検出できるか」も 95_drift_canary.sql で確かめる。

\echo '=== (0) 比べる対象が空でないこと ==='
SELECT (SELECT count(*) FROM ch11_r.src_order_line) = 0 AS source_is_empty,
       (SELECT count(*) FROM ch11_a.order_lines)    = 0 AS a_is_empty,
       (SELECT count(*) FROM ch11_b.daily_sales)    = 0 AS b_is_empty,
       (SELECT count(*) FROM ch11_c.daily_sales)    = 0 AS c_is_empty,
       (SELECT count(*) FROM ch11_d.daily_sales_final) = 0 AS d_is_empty;

\echo '=== (1) 元データと案B（マテリアライズドビュー）の差 ==='
-- 🔴 対称差は必ず括弧で囲む。囲まないと EXCEPT と UNION ALL が左結合になり、
--    片方向にしか働かない（第9章で 5 ファイルが同じ誤りだった）。
WITH src AS (
  SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS sales_date,
         l.product_id,
         sum(l.qty) AS qty,
         sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS net_yen
    FROM ch11_r.src_order_line l
    LEFT JOIN ch11_r.src_return r ON r.order_line_id = l.id
   GROUP BY 1, 2
), b AS (
  SELECT sales_date, product_id, qty, net_yen FROM ch11_b.daily_sales
)
SELECT count(*) AS src_vs_b_diff FROM (
  (SELECT * FROM src EXCEPT ALL SELECT * FROM b)
  UNION ALL
  (SELECT * FROM b EXCEPT ALL SELECT * FROM src)
) t;

\echo '=== (2) 元データと案C（集計テーブル）の差 ==='
WITH src AS (
  SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS sales_date,
         l.product_id,
         sum(l.qty) AS qty,
         sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS net_yen
    FROM ch11_r.src_order_line l
    LEFT JOIN ch11_r.src_return r ON r.order_line_id = l.id
   GROUP BY 1, 2
), c AS (
  SELECT sales_date, product_id, qty, net_yen FROM ch11_c.daily_sales
)
SELECT count(*) AS src_vs_c_diff FROM (
  (SELECT * FROM src EXCEPT ALL SELECT * FROM c)
  UNION ALL
  (SELECT * FROM c EXCEPT ALL SELECT * FROM src)
) t;

\echo '=== (3) 案D は「確定日 + 当日」で元データと一致すること ==='
-- 案D は当日の行を集計テーブルに持たないので、当日ぶんを足して比べる。
WITH src AS (
  SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS sales_date,
         l.product_id,
         sum(l.qty) AS qty,
         sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS net_yen
    FROM ch11_r.src_order_line l
    LEFT JOIN ch11_r.src_return r ON r.order_line_id = l.id
   GROUP BY 1, 2
), d AS (
  SELECT sales_date, product_id, qty, net_yen FROM ch11_d.daily_sales_final
  UNION ALL
  SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date, l.product_id,
         sum(l.qty), sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0)
    FROM ch11_d.order_lines l
    LEFT JOIN ch11_d.returns r ON r.order_line_id = l.id
   WHERE (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date
       = (now() AT TIME ZONE 'Asia/Tokyo')::date
   GROUP BY 1, 2
)
SELECT count(*) AS src_vs_d_diff FROM (
  (SELECT * FROM src EXCEPT ALL SELECT * FROM d)
  UNION ALL
  (SELECT * FROM d EXCEPT ALL SELECT * FROM src)
) t;

\echo '=== (4) 案A は元データそのものなので、合計が一致すること ==='
SELECT abs((SELECT sum(amount_yen) FROM ch11_a.order_lines)
         - (SELECT sum(amount_yen) FROM ch11_r.src_order_line)) AS a_vs_src_gross_diff;
