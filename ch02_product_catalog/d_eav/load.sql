-- 元データ（ch02_r.src）を id の順に写す。先に r_source/ の 2 つのファイルを実行しておく
-- 元データが空のまま写すと、空のテーブルで測ることになる。何も消す前に止める
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM ch02_r.src) THEN
    RAISE EXCEPTION '元データ ch02_r.src が空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on
DROP INDEX IF EXISTS ch02_d.products_kind_created,
  ch02_d.product_attributes_def_text, ch02_d.product_attributes_def_number;
TRUNCATE ch02_d.products, ch02_d.attribute_defs RESTART IDENTITY CASCADE;

INSERT INTO ch02_d.products OVERRIDING SYSTEM VALUE
SELECT id, kind, name, price, created_at FROM ch02_r.src ORDER BY id;
SELECT setval(pg_get_serial_sequence('ch02_d.products', 'id'),
              (SELECT max(id) FROM ch02_d.products));

-- 属性の定義は、元データの列から作る（種類ごとに、先頭の 3 つが必須）
INSERT INTO ch02_d.attribute_defs (kind, code, value_type, is_required)
SELECT kind, code, value_type, pos <= 3
FROM (VALUES
  ('apparel',   ARRAY['color','size','material','season','fit','sleeve_cm',
                      'length_cm','chest_cm','weight_g','pockets']),
  ('appliance', ARRAY['watt','voltage','warranty_months','width_mm','depth_mm',
                      'height_mm','weight_kg','noise_db','cord_cm','energy_rank']),
  ('book',      ARRAY['author','isbn','pages','publisher','published_year',
                      'edition','series_no','thickness_mm','age_from','chapters'])
) AS k (kind, codes)
CROSS JOIN LATERAL unnest(codes) WITH ORDINALITY AS u (code, pos)
CROSS JOIN LATERAL (
  SELECT CASE WHEN code IN ('color','size','material','season','fit',
                            'author','isbn','publisher')
              THEN 'text' ELSE 'number' END AS value_type
) AS t
ORDER BY kind, pos;

-- 1 商品の行を「属性の名前と値」の行に開き、属性の定義と突き合わせて入れる
INSERT INTO ch02_d.product_attributes
SELECT s.id, d.id,
       CASE WHEN d.value_type = 'text'   THEN e.value #>> '{}' END,
       CASE WHEN d.value_type = 'number' THEN (e.value #>> '{}')::numeric END
FROM ch02_r.src AS s
CROSS JOIN LATERAL jsonb_each(jsonb_strip_nulls(to_jsonb(s))) AS e
JOIN ch02_d.attribute_defs AS d ON d.kind = s.kind AND d.code = e.key
ORDER BY s.id, d.id;

-- インデックスは、採取した案のとおり
CREATE INDEX products_kind_created ON ch02_d.products (kind, created_at DESC);
CREATE INDEX product_attributes_def_text
  ON ch02_d.product_attributes (attribute_def_id, value_text);
CREATE INDEX product_attributes_def_number
  ON ch02_d.product_attributes (attribute_def_id, value_number);
VACUUM (ANALYZE) ch02_d.products, ch02_d.attribute_defs, ch02_d.product_attributes;
