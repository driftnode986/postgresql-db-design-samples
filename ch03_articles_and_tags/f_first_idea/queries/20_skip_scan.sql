-- 主キー (article_id, tag_id) だけでタグから引けるか。
-- 先頭列の種類が多いので skip scan は選ばれない。Index Searches に注目する
SET LOCAL enable_seqscan = off;
EXPLAIN (ANALYZE)
SELECT count(*) FROM ch03_f.article_tags WHERE tag_id = 150;
