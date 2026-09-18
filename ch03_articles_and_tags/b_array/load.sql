SELECT count(*) AS src_rows FROM ch03_r.articles_src \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch03_b.articles RESTART IDENTITY;
DROP INDEX IF EXISTS ch03_b.articles_published_at_idx;
DROP INDEX IF EXISTS ch03_b.articles_tags_gin;

INSERT INTO ch03_b.articles (title, body, published_at, tags)
OVERRIDING SYSTEM VALUE
SELECT a.title, a.body, a.published_at,
       array_agg(t.name ORDER BY t.name)
FROM ch03_r.articles_src a
JOIN ch03_r.article_tags_src at ON at.article_id = a.id
JOIN ch03_r.tags_src t ON t.id = at.tag_id
GROUP BY a.id, a.title, a.body, a.published_at
ORDER BY a.id;

CREATE INDEX articles_published_at_idx
  ON ch03_b.articles (published_at DESC, id);
CREATE INDEX articles_tags_gin ON ch03_b.articles USING gin (tags);

ANALYZE ch03_b.articles;
