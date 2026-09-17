-- 生成したデータが毎回同じかを、行数と内容のハッシュで確かめる
SELECT count(*) AS rows,
       md5(string_agg(product_id::text || ':' || qty::text, ',' ORDER BY id)) AS content_hash
FROM order_items;
