SELECT count(*) AS src_rows FROM ch03_r.articles_src \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch03_c.articles RESTART IDENTITY;
DROP INDEX IF EXISTS ch03_c.articles_published_at_idx;
DROP INDEX IF EXISTS ch03_c.articles_tags_gin;

INSERT INTO ch03_c.articles (title, body, published_at, tags)
OVERRIDING SYSTEM VALUE
SELECT a.title, a.body, a.published_at,
       jsonb_agg(t.name ORDER BY t.name)
FROM ch03_r.articles_src a
JOIN ch03_r.article_tags_src at ON at.article_id = a.id
JOIN ch03_r.tags_src t ON t.id = at.tag_id
GROUP BY a.id, a.title, a.body, a.published_at
ORDER BY a.id;

CREATE INDEX articles_published_at_idx
  ON ch03_c.articles (published_at DESC, id);
-- jsonb_path_ops は @> だけを支援する代わりに小さい。本章の検索は @> だけ
CREATE INDEX articles_tags_gin
  ON ch03_c.articles USING gin (tags jsonb_path_ops);

ANALYZE ch03_c.articles;
