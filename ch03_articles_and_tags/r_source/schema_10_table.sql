-- 第3章の元データ。3 案がここから同じ中身を写す（案ごとに作り直さない）。
CREATE SCHEMA IF NOT EXISTS ch03_r;

DROP TABLE IF EXISTS ch03_r.article_tags_src;
DROP TABLE IF EXISTS ch03_r.articles_src;
DROP TABLE IF EXISTS ch03_r.tags_src;

-- タグの一覧。165 種類で、順位が下がるほど出現率が下がる（幾何級数）
CREATE TABLE ch03_r.tags_src (
  id    smallint PRIMARY KEY,
  name  text NOT NULL UNIQUE
);

CREATE TABLE ch03_r.articles_src (
  id            bigint PRIMARY KEY,
  title         text NOT NULL,
  body          text NOT NULL,
  published_at  timestamptz NOT NULL
);

-- 記事とタグの対応。1 記事あたり 1〜5 個
CREATE TABLE ch03_r.article_tags_src (
  article_id  bigint   NOT NULL,
  tag_id      smallint NOT NULL
);
