-- 元データを写す。測定のたびに入れ直すので、在庫も毎回 100 個に戻る
SELECT count(*) AS src_rows FROM ch05_r.src_product \gset
SELECT CASE WHEN :src_rows = 0
            THEN 1/0 ELSE 1 END AS source_must_not_be_empty;  -- 空なら何も消さずに止まる

\timing on
TRUNCATE ch05_a.orders, ch05_a.order_items, ch05_a.inventory, ch05_a.products
  RESTART IDENTITY CASCADE;

INSERT INTO ch05_a.products (id, sku, name, price_yen)
OVERRIDING SYSTEM VALUE
SELECT id, sku, name, price_yen FROM ch05_r.src_product ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch05_a.products', 'id'),
              (SELECT max(id) FROM ch05_a.products));

INSERT INTO ch05_a.inventory (product_id, qty)
SELECT id, qty FROM ch05_r.src_product ORDER BY id;

ANALYZE ch05_a.products, ch05_a.inventory;
