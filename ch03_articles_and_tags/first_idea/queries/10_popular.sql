-- 採取した案の問い合わせ 1。人気タグ（tag001）なら速い
EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_f.articles a
INNER JOIN ch03_f.article_tags at ON a.id = at.article_id
WHERE at.tag_id = 1
ORDER BY a.published_at DESC
LIMIT 20;
