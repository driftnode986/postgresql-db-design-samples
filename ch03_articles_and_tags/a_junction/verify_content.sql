-- 元データと同じ中身が入っているか（全行の先頭列が 0 になること）
SELECT count(*) AS articles_diff FROM (
  SELECT id, title, published_at FROM ch03_a.articles
  EXCEPT SELECT id, title, published_at FROM ch03_r.articles_src) AS d;
SELECT count(*) AS assignments_diff FROM (
  SELECT article_id, tag_id FROM ch03_a.article_tags
  EXCEPT SELECT article_id, tag_id FROM ch03_r.article_tags_src) AS d;
SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_was_empty
  FROM ch03_r.articles_src;
