-- 元データと同じ商品と在庫が入っているか（全行の先頭列が 0 になること）
SELECT count(*) AS products_diff FROM (
  SELECT id, sku, name, price_yen FROM ch05_a.products
  EXCEPT SELECT id, sku, name, price_yen FROM ch05_r.src_product) AS d;
-- 🔴 在庫の数量は測定で減るので、ここでは比べない（load 直後にしか一致しない）。
--    行がそろっているかだけを見る
SELECT count(*) AS inventory_rows_diff FROM (
  SELECT product_id FROM ch05_a.inventory
  EXCEPT SELECT id FROM ch05_r.src_product) AS d;
SELECT count(*) AS rows_diff FROM (
  SELECT (SELECT count(*) FROM ch05_a.products)
       - (SELECT count(*) FROM ch05_r.src_product) AS n) AS x WHERE n <> 0;
SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_was_empty
  FROM ch05_r.src_product;
