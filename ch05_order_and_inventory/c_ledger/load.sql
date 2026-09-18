-- 元データを写す。案C は在庫数の列を持たないので、初期在庫を入荷の行として追記する
SELECT count(*) AS src_rows FROM ch05_r.src_product \gset
SELECT CASE WHEN :src_rows = 0
            THEN 1/0 ELSE 1 END AS source_must_not_be_empty;  -- 空なら何も消さずに止まる

\timing on
TRUNCATE ch05_c.orders, ch05_c.order_items, ch05_c.inventory_entries, ch05_c.products
  RESTART IDENTITY CASCADE;

INSERT INTO ch05_c.products (id, sku, name, price_yen)
OVERRIDING SYSTEM VALUE
SELECT id, sku, name, price_yen FROM ch05_r.src_product ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch05_c.products', 'id'),
              (SELECT max(id) FROM ch05_c.products));

-- 初期在庫は「入荷が 1 回あった」として記録する
INSERT INTO ch05_c.inventory_entries (product_id, delta, reason)
SELECT id, qty, 'receipt' FROM ch05_r.src_product ORDER BY id;

ANALYZE ch05_c.products, ch05_c.inventory_entries;
