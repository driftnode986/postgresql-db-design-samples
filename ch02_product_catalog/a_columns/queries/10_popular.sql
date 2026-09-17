-- よく出る値（色が black でサイズが M）の衣料を、新しい順に 20 件
EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE color = 'black' AND size = 'M'
ORDER BY created_at DESC
LIMIT 20;
