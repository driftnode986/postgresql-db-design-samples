-- 同じ AND 検索を、タグの id を先に引く形で書く
EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_a.article_tags at1
JOIN ch03_a.article_tags at2
  ON at2.article_id = at1.article_id
 AND at2.tag_id = (SELECT id FROM ch03_a.tags WHERE name = 'tag101')
JOIN ch03_a.articles a ON a.id = at1.article_id
WHERE at1.tag_id = (SELECT id FROM ch03_a.tags WHERE name = 'tag100')
ORDER BY a.published_at DESC, a.id
LIMIT 20;
