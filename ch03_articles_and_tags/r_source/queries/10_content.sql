-- 元データの中身を確かめる（偏りが入っているか）
SELECT count(*) AS articles FROM ch03_r.articles_src;
SELECT count(*) AS assignments,
       round(count(*)::numeric / (SELECT count(*) FROM ch03_r.articles_src), 3)
         AS tags_per_article
FROM ch03_r.article_tags_src;

-- タグごとの記事数（多い順・少ない順）
SELECT t.name, count(*) AS n
FROM ch03_r.article_tags_src at JOIN ch03_r.tags_src t ON t.id = at.tag_id
GROUP BY t.name ORDER BY n DESC LIMIT 5;
SELECT t.name, count(*) AS n
FROM ch03_r.article_tags_src at JOIN ch03_r.tags_src t ON t.id = at.tag_id
GROUP BY t.name ORDER BY n ASC LIMIT 5;

-- 1 記事あたりのタグ数の分布
SELECT k AS tags, count(*) AS articles FROM (
  SELECT article_id, count(*) AS k FROM ch03_r.article_tags_src GROUP BY article_id
) AS s GROUP BY k ORDER BY k;
