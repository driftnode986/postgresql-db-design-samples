-- 見積もりの行数（rows=）と実際の行数（actual rows=）を比べる。LIMIT を付けずに、条件に合う商品を全部取る
EXPLAIN (ANALYZE)
SELECT p.id
FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'black' AND a.size = 'M';
EXPLAIN (ANALYZE)
SELECT p.id
FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL';
EXPLAIN (ANALYZE)
SELECT p.id
FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'teal' AND a.size = 'XXS';
