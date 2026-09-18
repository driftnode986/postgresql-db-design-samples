-- 元データと同じ中身か（全行の先頭列が 0）
SELECT count(*) AS articles_diff FROM (
  SELECT id, title, published_at FROM ch03_b.articles
  EXCEPT SELECT id, title, published_at FROM ch03_r.articles_src) AS d;
-- タグの対応も、案A と同じ集合になっているか
SELECT count(*) AS assignments_diff FROM (
  SELECT id, unnest(tags) FROM ch03_b.articles
  EXCEPT
  SELECT at.article_id, t.name
  FROM ch03_r.article_tags_src at JOIN ch03_r.tags_src t ON t.id = at.tag_id) AS d;
SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_was_empty
  FROM ch03_r.articles_src;
