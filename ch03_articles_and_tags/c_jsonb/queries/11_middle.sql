-- 中くらいのタグ（tag050）
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_c.articles
WHERE tags @> '["tag050"]'::jsonb
ORDER BY published_at DESC, id
LIMIT 20;
