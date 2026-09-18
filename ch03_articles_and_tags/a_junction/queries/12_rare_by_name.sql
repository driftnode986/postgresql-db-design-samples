-- 珍しいタグ（tag150）。10・11 と同じ書き方。ここで計画の問題が表面化する
EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_a.articles a
JOIN ch03_a.article_tags at ON at.article_id = a.id
JOIN ch03_a.tags t ON t.id = at.tag_id
WHERE t.name = 'tag150'
ORDER BY a.published_at DESC, a.id
LIMIT 20;
