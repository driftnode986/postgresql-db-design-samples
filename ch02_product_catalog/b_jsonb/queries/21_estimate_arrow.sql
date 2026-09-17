-- 同じ 3 つの条件を ->> で書いたときの見積もり
EXPLAIN (ANALYZE)
SELECT id
FROM products
WHERE attrs->>'color' = 'black' AND attrs->>'size' = 'M';
EXPLAIN (ANALYZE)
SELECT id
FROM products
WHERE attrs->>'color' = 'yellow' AND attrs->>'size' = 'XL';
EXPLAIN (ANALYZE)
SELECT id
FROM products
WHERE attrs->>'color' = 'teal' AND attrs->>'size' = 'XXS';
