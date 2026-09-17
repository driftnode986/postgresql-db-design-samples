-- 珍しい値（色が teal でサイズが XXS）の衣料を、新しい順に 20 件
EXPLAIN (ANALYZE)
SELECT p.id, p.name, p.price, p.created_at
FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'teal' AND a.size = 'XXS'
ORDER BY p.created_at DESC
LIMIT 20;
