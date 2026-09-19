-- run-as: book_owner
-- 集計テーブルは、元データとズレうる。ズレを検出して直す。
--
-- 🔴 「検査が 0 を返した」だけでは、検査器が動いている証拠にならない
--    （第8章 C1）。ここでは **わざとズラして、検出できることを確かめてから**
--    直して 0 に戻す、という両方向を 1 つのファイルで示す。
\timing on

\echo '=== (1) まずズレていないことを確かめる ==='
SELECT count(*) AS mismatch
  FROM (SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS d, l.product_id,
               sum(l.qty) AS q,
               sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS n
          FROM ch11_c.order_lines l
          LEFT JOIN ch11_c.returns r ON r.order_line_id = l.id
         GROUP BY 1, 2) src
  FULL JOIN ch11_c.daily_sales ds
    ON ds.sales_date = src.d AND ds.product_id = src.product_id
 WHERE src.q IS DISTINCT FROM ds.qty OR src.n IS DISTINCT FROM ds.net_yen;

\echo '=== (2) わざとズラす（集計だけを書き換え、元データは触らない） ==='
-- 集計の更新を忘れた状態を作る。運用では「集計を更新しない経路が 1 つ残っていた」で起きる。
UPDATE ch11_c.daily_sales
   SET qty = qty + 1, gross_yen = gross_yen + 99999
 WHERE sales_date > (now() AT TIME ZONE 'Asia/Tokyo')::date - 5;

\echo '=== (3) 検査がそれを捕まえること（0 ではない数が出るのが正しい） ==='
SELECT count(*) AS mismatch_after_drift
  FROM (SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS d, l.product_id,
               sum(l.qty) AS q,
               sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS n
          FROM ch11_c.order_lines l
          LEFT JOIN ch11_c.returns r ON r.order_line_id = l.id
         GROUP BY 1, 2) src
  FULL JOIN ch11_c.daily_sales ds
    ON ds.sales_date = src.d AND ds.product_id = src.product_id
 WHERE src.q IS DISTINCT FROM ds.qty OR src.n IS DISTINCT FROM ds.net_yen;

\echo '=== (4) ズレた日だけを作り直す（MERGE） ==='
MERGE INTO ch11_c.daily_sales ds
USING (SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS sales_date,
              l.product_id, l.category_id,
              sum(l.qty) AS qty, sum(l.amount_yen) AS gross_yen,
              coalesce(sum(r.refund_yen), 0) AS refund_yen
         FROM ch11_c.order_lines l
         LEFT JOIN ch11_c.returns r ON r.order_line_id = l.id
        WHERE (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date
            > (now() AT TIME ZONE 'Asia/Tokyo')::date - 5
        GROUP BY 1, 2, 3) src
   ON ds.sales_date = src.sales_date AND ds.product_id = src.product_id
 WHEN MATCHED THEN UPDATE SET qty = src.qty, gross_yen = src.gross_yen,
                              refund_yen = src.refund_yen
 WHEN NOT MATCHED THEN INSERT (sales_date, product_id, category_id,
                               qty, gross_yen, refund_yen)
                       VALUES (src.sales_date, src.product_id, src.category_id,
                               src.qty, src.gross_yen, src.refund_yen);

\echo '=== (5) 直ったこと（0 に戻る） ==='
SELECT count(*) AS mismatch_after_repair
  FROM (SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS d, l.product_id,
               sum(l.qty) AS q,
               sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS n
          FROM ch11_c.order_lines l
          LEFT JOIN ch11_c.returns r ON r.order_line_id = l.id
         GROUP BY 1, 2) src
  FULL JOIN ch11_c.daily_sales ds
    ON ds.sales_date = src.d AND ds.product_id = src.product_id
 WHERE src.q IS DISTINCT FROM ds.qty OR src.n IS DISTINCT FROM ds.net_yen;
