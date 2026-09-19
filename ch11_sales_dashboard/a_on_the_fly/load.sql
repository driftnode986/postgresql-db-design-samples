-- 案A に元データを写す。
--
-- 🔴 元データが空なら、何も消す前に止める。
--    検証の実行順は schema → load なので、元データを作る schema_20_generate.sql が
--    走っていないと、全案が空のまま「全件 OK」になる（第2章で実際に起きた）。
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ch11_r.src_order_line) THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch11_a.returns;
TRUNCATE ch11_a.order_lines;

INSERT INTO ch11_a.order_lines
       (id, order_id, product_id, category_id, qty, amount_yen, ordered_at)
SELECT id, order_id, product_id, category_id, qty, amount_yen, ordered_at
  FROM ch11_r.src_order_line ORDER BY id;

INSERT INTO ch11_a.returns
       (id, order_line_id, sales_date, returned_at, qty, refund_yen)
SELECT id, order_line_id, sales_date, returned_at, qty, refund_yen
  FROM ch11_r.src_return ORDER BY id;

-- 🔴 インデックスはデータを入れてから作る。
--    付けたまま入れると充填率が 90 から 67 に下がり、
--    サイズが実行のたびに変わる（docs/measurement-rules.yml の sizes）。
--
-- 🔴 案A のための式インデックス。日付で絞るので、集計キーそのものに張る。
--    INCLUDE に集計する列を入れて、ヒープを読まずに済むことを狙う
--    （狙いどおりにならないことは本文で扱う。ch11_verification.md §1）。
CREATE INDEX order_lines_sales_date
  ON ch11_a.order_lines (((ordered_at AT TIME ZONE 'Asia/Tokyo')::date), product_id)
  INCLUDE (qty, amount_yen);

CREATE INDEX returns_sales_date ON ch11_a.returns (sales_date);

ANALYZE ch11_a.order_lines;
ANALYZE ch11_a.returns;

\echo '=== 案A の件数 ==='
SELECT (SELECT count(*) FROM ch11_a.order_lines) AS lines,
       (SELECT count(*) FROM ch11_a.returns)     AS returns;
