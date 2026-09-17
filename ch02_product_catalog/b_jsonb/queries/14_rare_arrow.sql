-- 珍しい値を ->> で書く
EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE attrs->>'color' = 'teal' AND attrs->>'size' = 'XXS'
ORDER BY created_at DESC
LIMIT 20;
