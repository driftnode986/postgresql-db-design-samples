-- 人気タグ（tag001）の記事を新しい順に 20 件
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_b.articles
WHERE tags @> ARRAY['tag001']
ORDER BY published_at DESC, id
LIMIT 20;
