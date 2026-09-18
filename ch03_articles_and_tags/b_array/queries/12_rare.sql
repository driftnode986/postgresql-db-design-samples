-- 珍しいタグ（tag150）
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_b.articles
WHERE tags @> ARRAY['tag150']
ORDER BY published_at DESC, id
LIMIT 20;
