-- 珍しい値（色が teal でサイズが XXS）の衣料を、新しい順に 20 件
EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE color = 'teal' AND size = 'XXS'
ORDER BY created_at DESC
LIMIT 20;
