-- 見積もりの行数（rows=）と実際の行数（actual rows=）を比べる。LIMIT を付けずに、条件に合う商品を全部取る
EXPLAIN (ANALYZE)
SELECT id
FROM products
WHERE attrs @> '{"color": "black", "size": "M"}';
EXPLAIN (ANALYZE)
SELECT id
FROM products
WHERE attrs @> '{"color": "yellow", "size": "XL"}';
EXPLAIN (ANALYZE)
SELECT id
FROM products
WHERE attrs @> '{"color": "teal", "size": "XXS"}';
