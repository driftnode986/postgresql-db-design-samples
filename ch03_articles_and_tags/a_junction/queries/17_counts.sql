-- タグごとの記事数（多い順 20 件）
EXPLAIN (ANALYZE)
SELECT t.name, count(*) AS n
FROM ch03_a.article_tags at
JOIN ch03_a.tags t ON t.id = at.tag_id
GROUP BY t.name
ORDER BY n DESC
LIMIT 20;
