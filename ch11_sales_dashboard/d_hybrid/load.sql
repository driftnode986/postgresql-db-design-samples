-- 案D に元データを写し、確定した日だけの集計テーブルを作る。
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ch11_r.src_order_line) THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch11_d.daily_sales_final;
TRUNCATE ch11_d.returns;
TRUNCATE ch11_d.order_lines;

INSERT INTO ch11_d.order_lines
       (id, order_id, product_id, category_id, qty, amount_yen, ordered_at)
SELECT id, order_id, product_id, category_id, qty, amount_yen, ordered_at
  FROM ch11_r.src_order_line ORDER BY id;

INSERT INTO ch11_d.returns
       (id, order_line_id, sales_date, returned_at, qty, refund_yen)
SELECT id, order_line_id, sales_date, returned_at, qty, refund_yen
  FROM ch11_r.src_return ORDER BY id;

-- 🔴 当日ぶんを都度集計するので、集計キーの式インデックスを張る。
--    案A と同じ形のインデックスだが、読む範囲が当日の 1 日だけになる。
CREATE INDEX d_order_lines_sales_date
  ON ch11_d.order_lines (((ordered_at AT TIME ZONE 'Asia/Tokyo')::date), product_id)
  INCLUDE (qty, amount_yen);

CREATE INDEX d_returns_sales_date ON ch11_d.returns (sales_date);

-- 確定した日（当日より前）だけを集計テーブルに入れる。
INSERT INTO ch11_d.daily_sales_final
       (sales_date, product_id, category_id, qty, gross_yen, refund_yen)
SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date,
       l.product_id, l.category_id,
       sum(l.qty), sum(l.amount_yen),
       coalesce(sum(r.refund_yen), 0)
  FROM ch11_d.order_lines l
  LEFT JOIN ch11_d.returns r ON r.order_line_id = l.id
 WHERE (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date
     < (now() AT TIME ZONE 'Asia/Tokyo')::date
 GROUP BY 1, 2, 3
 ORDER BY 1, 2;

ANALYZE ch11_d.order_lines;
ANALYZE ch11_d.returns;
ANALYZE ch11_d.daily_sales_final;

\echo '=== 案D の件数（当日の行は集計テーブルに入れない） ==='
SELECT (SELECT count(*) FROM ch11_d.order_lines)        AS lines,
       (SELECT count(*) FROM ch11_d.daily_sales_final)  AS final_rows,
       (SELECT count(*) FROM ch11_d.order_lines
         WHERE (ordered_at AT TIME ZONE 'Asia/Tokyo')::date
             = (now() AT TIME ZONE 'Asia/Tokyo')::date) AS today_lines;
