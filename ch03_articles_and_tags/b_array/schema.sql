-- 案B: タグを記事の列に text の配列として持つ
CREATE SCHEMA ch03_b;

CREATE TABLE ch03_b.articles (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title         text NOT NULL,
  body          text NOT NULL,
  published_at  timestamptz NOT NULL,
  tags          text[] NOT NULL
    -- 1 記事 5 個までは、案A では制約として書けない（CHECK に副問い合わせを書けない）
    CONSTRAINT tags_max_5 CHECK (cardinality(tags) <= 5)
);
