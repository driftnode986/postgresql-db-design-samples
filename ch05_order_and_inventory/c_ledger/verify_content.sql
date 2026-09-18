-- 元データと同じ商品が入り、入荷の合計が初期在庫と一致するか（全行の先頭列が 0 になること）
SELECT count(*) AS products_diff FROM (
  SELECT id, sku, name, price_yen FROM ch05_c.products
  EXCEPT SELECT id, sku, name, price_yen FROM ch05_r.src_product) AS d;
-- 🔴 有効在庫は測定で減るので、ここでは比べない。商品がそろっているかだけを見る
SELECT count(*) AS available_rows_diff FROM (
  SELECT product_id FROM ch05_c.available
  EXCEPT SELECT id FROM ch05_r.src_product) AS d;
SELECT count(*) AS rows_diff FROM (
  SELECT (SELECT count(*) FROM ch05_c.products)
       - (SELECT count(*) FROM ch05_r.src_product) AS n) AS x WHERE n <> 0;
SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_was_empty
  FROM ch05_r.src_product;
