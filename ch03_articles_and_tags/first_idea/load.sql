SELECT count(*) AS src_rows FROM ch03_r.articles_src \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch03_f.article_tags, ch03_f.articles, ch03_f.tags RESTART IDENTITY CASCADE;
DROP INDEX IF EXISTS ch03_f.articles_published_at_idx;
DROP INDEX IF EXISTS ch03_f.article_tags_tag_id_idx;

INSERT INTO ch03_f.tags (name) OVERRIDING SYSTEM VALUE
SELECT name FROM ch03_r.tags_src ORDER BY id;
INSERT INTO ch03_f.articles (title, body, published_at) OVERRIDING SYSTEM VALUE
SELECT title, body, published_at FROM ch03_r.articles_src ORDER BY id;
INSERT INTO ch03_f.article_tags (article_id, tag_id)
SELECT article_id, tag_id FROM ch03_r.article_tags_src ORDER BY article_id, tag_id;

-- 採取した案のインデックス（tag_id は単独。published_at は親側）
CREATE INDEX articles_published_at_idx ON ch03_f.articles (published_at DESC);
CREATE INDEX article_tags_tag_id_idx   ON ch03_f.article_tags (tag_id);

ANALYZE ch03_f.tags;
ANALYZE ch03_f.articles;
ANALYZE ch03_f.article_tags;
