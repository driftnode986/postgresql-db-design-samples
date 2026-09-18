-- 中くらいのタグ（tag050）
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_b.articles
WHERE tags @> ARRAY['tag050']
ORDER BY published_at DESC, id
LIMIT 20;
