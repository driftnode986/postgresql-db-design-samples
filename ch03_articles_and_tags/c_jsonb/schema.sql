-- 案C: タグを記事の列に jsonb の配列として持つ
CREATE SCHEMA ch03_c;

CREATE TABLE ch03_c.articles (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title         text NOT NULL,
  body          text NOT NULL,
  published_at  timestamptz NOT NULL,
  tags          jsonb NOT NULL
    CONSTRAINT tags_is_array_max_5 CHECK (
      jsonb_typeof(tags) = 'array' AND jsonb_array_length(tags) <= 5)
);
