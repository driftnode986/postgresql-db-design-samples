-- 人気タグ（tag001）の記事を新しい順に 20 件
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_c.articles
WHERE tags @> '["tag001"]'::jsonb
ORDER BY published_at DESC, id
LIMIT 20;
