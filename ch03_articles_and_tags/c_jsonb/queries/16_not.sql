-- tag100 が付いていて tag101 が付いていない記事
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_c.articles
WHERE tags @> '["tag100"]'::jsonb
  AND NOT tags @> '["tag101"]'::jsonb
ORDER BY published_at DESC, id
LIMIT 20;
