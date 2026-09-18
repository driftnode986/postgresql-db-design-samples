-- 人気タグ（tag001）の記事を新しい順に 20 件。タグ名で結合する 1 文で書く
EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_a.articles a
JOIN ch03_a.article_tags at ON at.article_id = a.id
JOIN ch03_a.tags t ON t.id = at.tag_id
WHERE t.name = 'tag001'
ORDER BY a.published_at DESC, a.id
LIMIT 20;
