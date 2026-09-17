-- 中くらいの頻度の値（色が yellow でサイズが XL）の衣料を、新しい順に 20 件
EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE color = 'yellow' AND size = 'XL'
ORDER BY created_at DESC
LIMIT 20;
