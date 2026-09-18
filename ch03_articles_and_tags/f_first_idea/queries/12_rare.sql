-- 同じ問い合わせを珍しいタグ（tag150）で。ここで計画が変わる
EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_f.articles a
INNER JOIN ch03_f.article_tags at ON a.id = at.article_id
WHERE at.tag_id = 150
ORDER BY a.published_at DESC
LIMIT 20;
