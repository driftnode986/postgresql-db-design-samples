-- 案A: タグを行として持ち、記事とタグを中間テーブルでつなぐ
CREATE SCHEMA ch03_a;

CREATE TABLE ch03_a.articles (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title         text NOT NULL,
  body          text NOT NULL,
  published_at  timestamptz NOT NULL
);

CREATE TABLE ch03_a.tags (
  id    smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name  text NOT NULL UNIQUE
);

CREATE TABLE ch03_a.article_tags (
  article_id  bigint   NOT NULL
                REFERENCES ch03_a.articles(id) ON DELETE CASCADE,
  tag_id      smallint NOT NULL REFERENCES ch03_a.tags(id),
  PRIMARY KEY (article_id, tag_id)
);
