-- 案C に元データを写し、集計テーブルを作る。
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ch11_r.src_order_line) THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch11_c.daily_sales;
TRUNCATE ch11_c.returns;
TRUNCATE ch11_c.order_lines;

INSERT INTO ch11_c.order_lines
       (id, order_id, product_id, category_id, qty, amount_yen, ordered_at)
SELECT id, order_id, product_id, category_id, qty, amount_yen, ordered_at
  FROM ch11_r.src_order_line ORDER BY id;

INSERT INTO ch11_c.returns
       (id, order_line_id, sales_date, returned_at, qty, refund_yen)
SELECT id, order_line_id, sales_date, returned_at, qty, refund_yen
  FROM ch11_r.src_return ORDER BY id;

CREATE INDEX c_order_lines_ordered_at ON ch11_c.order_lines (ordered_at);
CREATE INDEX c_returns_sales_date     ON ch11_c.returns (sales_date);

-- 集計テーブルの初期値を、元データから 1 回だけ作る。
-- 以降は注文が入るたびに差分更新する（30_incremental.sql）。
INSERT INTO ch11_c.daily_sales
       (sales_date, product_id, category_id, qty, gross_yen, refund_yen)
SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date,
       l.product_id, l.category_id,
       sum(l.qty), sum(l.amount_yen),
       coalesce(sum(r.refund_yen), 0)
  FROM ch11_c.order_lines l
  LEFT JOIN ch11_c.returns r ON r.order_line_id = l.id
 GROUP BY 1, 2, 3
 ORDER BY 1, 2;

ANALYZE ch11_c.order_lines;
ANALYZE ch11_c.returns;
ANALYZE ch11_c.daily_sales;

\echo '=== 案C の件数 ==='
SELECT (SELECT count(*) FROM ch11_c.order_lines) AS lines,
       (SELECT count(*) FROM ch11_c.daily_sales) AS summary_rows;
