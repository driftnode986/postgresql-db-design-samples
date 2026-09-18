-- tag100 が付いていて tag101 が付いていない記事
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_b.articles
WHERE tags @> ARRAY['tag100']
  AND NOT tags @> ARRAY['tag101']
ORDER BY published_at DESC, id
LIMIT 20;
