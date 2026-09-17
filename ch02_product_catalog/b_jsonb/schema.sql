-- 案B: 種類ごとの属性を 1 つの jsonb の列に入れる
CREATE SCHEMA ch02_b;
CREATE TABLE ch02_b.products (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind        text        NOT NULL
              CHECK (kind IN ('apparel', 'appliance', 'book')),
  name        text        NOT NULL,
  price       int         NOT NULL CHECK (price >= 0),
  created_at  timestamptz NOT NULL DEFAULT now(),
  attrs       jsonb       NOT NULL DEFAULT '{}',
  -- 配列や文字列ではなく、{"キー": 値} の形だけを受け付ける
  CONSTRAINT attrs_is_object CHECK (attrs IS JSON OBJECT),
  -- 種類ごとの必須の項目。?& は「右の配列のキーをすべて持つ」
  CONSTRAINT apparel_required CHECK (kind <> 'apparel'
    OR attrs ?& ARRAY['color', 'size', 'material']),
  CONSTRAINT appliance_required CHECK (kind <> 'appliance'
    OR attrs ?& ARRAY['watt', 'voltage', 'warranty_months']),
  CONSTRAINT book_required CHECK (kind <> 'book'
    OR attrs ?& ARRAY['author', 'isbn', 'pages']),
  -- 数値の項目には数値だけを入れる（キーが無い行は NULL になり、CHECK を通る）
  CONSTRAINT watt_is_number CHECK (jsonb_typeof(attrs->'watt') = 'number'),
  CONSTRAINT pages_is_number CHECK (jsonb_typeof(attrs->'pages') = 'number')
);
