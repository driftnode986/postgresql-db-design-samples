-- 珍しいタグ（tag150）
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_c.articles
WHERE tags @> '["tag150"]'::jsonb
ORDER BY published_at DESC, id
LIMIT 20;
