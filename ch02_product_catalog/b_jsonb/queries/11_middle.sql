-- 中くらいの頻度の値（色が yellow でサイズが XL）の衣料を、新しい順に 20 件。@>（含む）で書く
EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE attrs @> '{"color": "yellow", "size": "XL"}'
ORDER BY created_at DESC
LIMIT 20;
