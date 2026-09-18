-- よく使われるタグ 2 つの AND 検索。タグ名で結合する書き方
EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_a.articles a
JOIN ch03_a.article_tags at1 ON at1.article_id = a.id
JOIN ch03_a.tags t1 ON t1.id = at1.tag_id
JOIN ch03_a.article_tags at2 ON at2.article_id = a.id
JOIN ch03_a.tags t2 ON t2.id = at2.tag_id
WHERE t1.name = 'tag001' AND t2.name = 'tag002'
ORDER BY a.published_at DESC, a.id
LIMIT 20;
