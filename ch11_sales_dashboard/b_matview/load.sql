-- 案B に元データを写し、マテリアライズドビューを作る。
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ch11_r.src_order_line) THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch11_b.returns;
TRUNCATE ch11_b.order_lines;

INSERT INTO ch11_b.order_lines
       (id, order_id, product_id, category_id, qty, amount_yen, ordered_at)
SELECT id, order_id, product_id, category_id, qty, amount_yen, ordered_at
  FROM ch11_r.src_order_line ORDER BY id;

INSERT INTO ch11_b.returns
       (id, order_line_id, sales_date, returned_at, qty, refund_yen)
SELECT id, order_line_id, sales_date, returned_at, qty, refund_yen
  FROM ch11_r.src_return ORDER BY id;

CREATE INDEX b_order_lines_ordered_at ON ch11_b.order_lines (ordered_at);
CREATE INDEX b_returns_sales_date     ON ch11_b.returns (sales_date);

ANALYZE ch11_b.order_lines;
ANALYZE ch11_b.returns;

-- 集計をマテリアライズドビューに保存する。
--
-- 🔴 返品を引いた金額まで持たせる。画面が出すのは返品後の売上なので、
--    ここで引いておかないと読み取り時に返品テーブルを見に行くことになり、
--    保存した意味が薄れる。
-- 🔴 GROUP BY に category_id を入れない。
--    カテゴリは商品に従属するので、集計キーは (sales_date, product_id) だけでよい。
--    入れてしまうと、同じ商品に違うカテゴリの行が 1 件でも混ざったときに
--    同じ (sales_date, product_id) の行が 2 つでき、**一意インデックスが作れなくなる**。
--    実際にこれを踏んだ（明細に誤ったカテゴリを 1 行入れたら REFRESH が
--    「Key (sales_date, product_id)=(...) is duplicated」で落ちた）。
--    カテゴリは min() で 1 つに決める（商品ごとに 1 つしかない前提を、ここで固定する）。
CREATE MATERIALIZED VIEW ch11_b.daily_sales AS
SELECT (l.ordered_at AT TIME ZONE 'Asia/Tokyo')::date AS sales_date,
       l.product_id,
       min(l.category_id)                             AS category_id,
       sum(l.qty)                                     AS qty,
       sum(l.amount_yen)                              AS gross_yen,
       coalesce(sum(r.refund_yen), 0)                 AS refund_yen,
       sum(l.amount_yen) - coalesce(sum(r.refund_yen), 0) AS net_yen
  FROM ch11_b.order_lines l
  LEFT JOIN ch11_b.returns r ON r.order_line_id = l.id
 GROUP BY 1, 2;

-- 🔴 REFRESH ... CONCURRENTLY には「素の一意インデックス」が要る。
--    WHERE 付き・式・非一意のどれでも失敗し、**エラー文は 3 つとも同じ**なので
--    原因が分からない（ch11_verification.md §3 で 5 通りを実機確認）。
CREATE UNIQUE INDEX daily_sales_pk
  ON ch11_b.daily_sales (sales_date, product_id);

ANALYZE ch11_b.daily_sales;

\echo '=== 案B の件数 ==='
SELECT (SELECT count(*) FROM ch11_b.order_lines) AS lines,
       (SELECT count(*) FROM ch11_b.daily_sales) AS summary_rows;
