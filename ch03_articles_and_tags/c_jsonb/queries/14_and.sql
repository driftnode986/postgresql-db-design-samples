-- 珍しいタグ 2 つの AND 検索。@> の右辺に 2 つ並べる 1 文で書ける
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_c.articles
WHERE tags @> '["tag100","tag101"]'::jsonb
ORDER BY published_at DESC, id
LIMIT 20;
