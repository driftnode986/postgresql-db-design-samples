-- あとで変えるのが大変な点: 案B から案A の形へ移す。
-- 配列を行に展開して中間テーブルへ入れる 1 文で書ける
\timing on
BEGIN;
CREATE TABLE ch03_b.article_tags_migrated (
  article_id  bigint   NOT NULL,
  tag_name    text     NOT NULL,
  PRIMARY KEY (article_id, tag_name)
);
INSERT INTO ch03_b.article_tags_migrated (article_id, tag_name)
SELECT id, unnest(tags) FROM ch03_b.articles;
SELECT count(*) AS migrated_rows FROM ch03_b.article_tags_migrated;
ROLLBACK;
