-- よく使われるタグ 2 つの AND 検索。@> の右辺に 2 つ並べる 1 文で書ける
EXPLAIN (ANALYZE)
SELECT id, title, published_at
FROM ch03_b.articles
WHERE tags @> ARRAY['tag001','tag002']
ORDER BY published_at DESC, id
LIMIT 20;
