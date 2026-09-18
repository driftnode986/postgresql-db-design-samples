-- タグごとの記事数（多い順 20 件）。配列を行に展開して数える
EXPLAIN (ANALYZE)
SELECT tag, count(*) AS n
FROM ch03_c.articles, jsonb_array_elements_text(tags) AS tag
GROUP BY tag
ORDER BY n DESC
LIMIT 20;
