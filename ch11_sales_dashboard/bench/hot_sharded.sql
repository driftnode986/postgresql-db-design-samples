-- 集計あり・1 商品に集中・集計行を 16 分割（緩和策）
SELECT ch11_c.place_order_sharded(1, 1, 15000);
