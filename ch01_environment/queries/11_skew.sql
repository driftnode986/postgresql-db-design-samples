-- 偏りの確認。上位 1% の商品（100 商品）が、注文の何 % を占めるか
SELECT round(100.0 * count(*) FILTER (WHERE product_id <= 100) / count(*), 1) AS top1pct_share,
       count(DISTINCT product_id) AS products
FROM order_items;
