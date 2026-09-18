-- 採取した案の問い合わせ 2。珍しいタグ 2 つの AND 検索
EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_f.articles a
INNER JOIN ch03_f.article_tags at1 ON a.id = at1.article_id
INNER JOIN ch03_f.article_tags at2 ON a.id = at2.article_id
WHERE at1.tag_id = 100 AND at2.tag_id = 101
ORDER BY a.published_at DESC
LIMIT 20;
