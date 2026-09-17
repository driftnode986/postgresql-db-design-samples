-- 参考の案D: 属性を「商品・属性・値」の 3 つ組で縦に持つ（EAV）。
-- 要件だけを AI に渡して採取した案の 1 つ。主キーの定義だけ、本書の規約
-- （bigint の IDENTITY）に合わせた
CREATE SCHEMA ch02_d;
CREATE TABLE ch02_d.products (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind        text        NOT NULL
              CHECK (kind IN ('apparel', 'appliance', 'book')),
  name        text        NOT NULL,
  price       int         NOT NULL CHECK (price >= 0),
  created_at  timestamptz NOT NULL DEFAULT now()
);
-- 属性の定義。運営が属性を足すと、ここに 1 行増える
CREATE TABLE ch02_d.attribute_defs (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind         text    NOT NULL CHECK (kind IN ('apparel', 'appliance', 'book')),
  code         text    NOT NULL,
  value_type   text    NOT NULL CHECK (value_type IN ('text', 'number')),
  is_required  boolean NOT NULL DEFAULT false,
  UNIQUE (kind, code)
);
-- 属性の値。1 商品につき、持っている属性の数だけ行ができる
CREATE TABLE ch02_d.product_attributes (
  product_id        bigint NOT NULL REFERENCES ch02_d.products (id) ON DELETE CASCADE,
  attribute_def_id  bigint NOT NULL REFERENCES ch02_d.attribute_defs (id),
  value_text        text,
  value_number      numeric,
  PRIMARY KEY (product_id, attribute_def_id),
  CHECK ((value_text IS NOT NULL AND value_number IS NULL)
      OR (value_text IS NULL AND value_number IS NOT NULL))
);
