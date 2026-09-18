-- tag100 が付いていて tag101 が付いていない記事
SELECT id AS tag100 FROM ch03_a.tags WHERE name = 'tag100' \gset
SELECT id AS tag101 FROM ch03_a.tags WHERE name = 'tag101' \gset

EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_a.article_tags at
JOIN ch03_a.articles a ON a.id = at.article_id
WHERE at.tag_id = :tag100
  AND NOT EXISTS (
    SELECT 1 FROM ch03_a.article_tags x
    WHERE x.article_id = at.article_id AND x.tag_id = :tag101)
ORDER BY a.published_at DESC, a.id
LIMIT 20;
