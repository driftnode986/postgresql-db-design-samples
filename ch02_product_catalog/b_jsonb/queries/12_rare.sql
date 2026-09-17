-- 珍しい値（色が teal でサイズが XXS）の衣料を、新しい順に 20 件。@>（含む）で書く
EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE attrs @> '{"color": "teal", "size": "XXS"}'
ORDER BY created_at DESC
LIMIT 20;
