-- 「最初に思いつく案」の検算用。採取した案（haiku）のとおりに作る。
-- 主キーは (article_id, tag_id)、タグからの逆引きは tag_id の単独インデックス
CREATE SCHEMA ch03_f;

CREATE TABLE ch03_f.articles (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title         text NOT NULL,
  body          text NOT NULL,
  published_at  timestamptz NOT NULL
);

CREATE TABLE ch03_f.tags (
  id    smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name  text NOT NULL UNIQUE
);

CREATE TABLE ch03_f.article_tags (
  article_id  bigint   NOT NULL
                REFERENCES ch03_f.articles(id) ON DELETE CASCADE,
  tag_id      smallint NOT NULL REFERENCES ch03_f.tags(id),
  PRIMARY KEY (article_id, tag_id)
);
