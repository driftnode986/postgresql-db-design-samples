-- 同じ条件を ->>（キーの値を文字列で取り出す）で書く。GIN インデックスは使われない
EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE attrs->>'color' = 'black' AND attrs->>'size' = 'M'
ORDER BY created_at DESC
LIMIT 20;
