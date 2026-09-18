-- tag100 が付いていて tag101 が付いていない記事
EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_a.article_tags at
JOIN ch03_a.articles a ON a.id = at.article_id
WHERE at.tag_id = 100
  AND NOT EXISTS (
    SELECT 1 FROM ch03_a.article_tags x
    WHERE x.article_id = at.article_id AND x.tag_id = 101)
ORDER BY a.published_at DESC, a.id
LIMIT 20;
