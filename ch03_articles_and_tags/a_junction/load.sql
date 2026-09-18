-- 元データを写す。インデックスはデータを入れてから作る（充填率を一定にするため）
SELECT count(*) AS src_rows FROM ch03_r.articles_src \gset
SELECT CASE WHEN :src_rows = 0
            THEN 1/0 ELSE 1 END AS source_must_not_be_empty;  -- 空なら何も消さずに止まる

\timing on
TRUNCATE ch03_a.article_tags, ch03_a.articles, ch03_a.tags RESTART IDENTITY CASCADE;
DROP INDEX IF EXISTS ch03_a.articles_published_at_idx;
DROP INDEX IF EXISTS ch03_a.article_tags_tag_id_article_id_idx;

INSERT INTO ch03_a.tags (name)
OVERRIDING SYSTEM VALUE
SELECT name FROM ch03_r.tags_src ORDER BY id;

INSERT INTO ch03_a.articles (title, body, published_at)
OVERRIDING SYSTEM VALUE
SELECT title, body, published_at FROM ch03_r.articles_src ORDER BY id;

INSERT INTO ch03_a.article_tags (article_id, tag_id)
SELECT article_id, tag_id FROM ch03_r.article_tags_src ORDER BY article_id, tag_id;

CREATE INDEX articles_published_at_idx
  ON ch03_a.articles (published_at DESC, id);
-- 逆引き（タグから記事へ）。主キーは (article_id, tag_id) なのでタグからは引けない
CREATE INDEX article_tags_tag_id_article_id_idx
  ON ch03_a.article_tags (tag_id, article_id);

ANALYZE ch03_a.tags;
ANALYZE ch03_a.articles;
ANALYZE ch03_a.article_tags;
