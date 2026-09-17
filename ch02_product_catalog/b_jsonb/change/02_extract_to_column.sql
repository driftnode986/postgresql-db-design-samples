-- あとで変えるのが大変な点: jsonb に入れた属性（color）を、通常の列へ取り出す。
-- テーブルを止めずにできるが、全行を 2 回更新するので、総サイズが一時的に大きくなる。
-- 必須の項目の CHECK が attrs の中の color を見ているので、制約も置き換える
\timing on
SELECT pg_size_pretty(pg_total_relation_size('ch02_b.products')) AS total_before;

ALTER TABLE ch02_b.products ADD COLUMN color text;
UPDATE ch02_b.products SET color = attrs->>'color' WHERE attrs ? 'color';
ALTER TABLE ch02_b.products
  DROP CONSTRAINT apparel_required,
  ADD CONSTRAINT apparel_required CHECK (kind <> 'apparel'
    OR (color IS NOT NULL AND attrs ?& ARRAY['size', 'material']));
UPDATE ch02_b.products SET attrs = attrs - 'color' WHERE attrs ? 'color';
SELECT pg_size_pretty(pg_total_relation_size('ch02_b.products')) AS total_after;

-- 元に戻す。テーブルが大きくなったままなので、測定を続けるときは load.sql で入れ直す
UPDATE ch02_b.products SET attrs = attrs || jsonb_build_object('color', color)
WHERE color IS NOT NULL;
ALTER TABLE ch02_b.products
  DROP CONSTRAINT apparel_required,
  ADD CONSTRAINT apparel_required CHECK (kind <> 'apparel'
    OR attrs ?& ARRAY['color', 'size', 'material']);
ALTER TABLE ch02_b.products DROP COLUMN color;
