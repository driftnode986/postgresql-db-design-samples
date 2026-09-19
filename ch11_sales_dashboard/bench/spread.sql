-- 集計あり・商品が散る（1,000 商品に均等）
\set pid random(1, 1000)
SELECT ch11_c.place_order(:pid, 1, 15000);
