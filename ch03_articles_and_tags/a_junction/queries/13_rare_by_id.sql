-- 珍しいタグ（tag150）を、タグの id を先に引いてから記事を引く形で書く。
-- アプリケーションは 2 回に分けて問い合わせ、2 文目には id を定数として渡す。
-- 12 と同じ結果を返すが、tag_id の統計が効くので計画が変わる
EXPLAIN (ANALYZE)
SELECT a.id, a.title, a.published_at
FROM ch03_a.article_tags at
JOIN ch03_a.articles a ON a.id = at.article_id
WHERE at.tag_id = 150          -- SELECT id FROM tags WHERE name = 'tag150' の結果
ORDER BY a.published_at DESC, a.id
LIMIT 20;
