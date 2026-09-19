-- run-as: book_owner
-- マテリアライズドビューは、元のテーブルを変えても自動では変わらない。
--
-- 🔴 これは不具合ではなく仕様である。公式も
--    「the data is not always current」と書いている。
--    「鮮度を捨てるかわりに速さを買う」選択であることを、数字で示す。
\timing on

\echo '=== (1) 元のテーブルと、マテリアライズドビューの合計（変更前） ==='
SELECT (SELECT sum(amount_yen) FROM ch11_b.order_lines) AS source_gross,
       (SELECT sum(gross_yen)  FROM ch11_b.daily_sales) AS matview_gross;

\echo '=== (2) 元のテーブルに 1 行入れる ==='
-- 🔴 カテゴリは商品マスタから引く。手で書くと、その商品の本当のカテゴリと
--    食い違った行ができる（実際に踏んだ。集計キーに category_id を入れていた頃は
--    それだけで REFRESH が一意制約違反で落ちた）。
INSERT INTO ch11_b.order_lines
       (id, order_id, product_id, category_id, qty, amount_yen, ordered_at)
SELECT 999000001, 999000001, 1, p.category_id, 1, 999999, now()
  FROM ch11_r.src_product p WHERE p.id = 1;

\echo '=== (3) もう一度読む: 元は増えたが、ビューは変わらない ==='
SELECT (SELECT sum(amount_yen) FROM ch11_b.order_lines) AS source_gross,
       (SELECT sum(gross_yen)  FROM ch11_b.daily_sales) AS matview_gross;

\echo '=== (4) REFRESH すると追いつく ==='
REFRESH MATERIALIZED VIEW ch11_b.daily_sales;

SELECT (SELECT sum(amount_yen) FROM ch11_b.order_lines) AS source_gross,
       (SELECT sum(gross_yen)  FROM ch11_b.daily_sales) AS matview_gross;

\echo '=== (5) 後片付け（入れた 1 行を戻す） ==='
DELETE FROM ch11_b.order_lines WHERE id = 999000001;
REFRESH MATERIALIZED VIEW ch11_b.daily_sales;
