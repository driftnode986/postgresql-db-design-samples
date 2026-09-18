-- 元データ（ch02_r.src）を id の順に写す。先に r_source/ の 2 つのファイルを実行しておく
-- 元データが空のまま写すと、空のテーブルで測ることになる。何も消す前に止める
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM ch02_r.src) THEN
    RAISE EXCEPTION '元データ ch02_r.src が空。先に r_source/schema_20_generate.sql を実行';
  END IF;
END $$;

\timing on
DROP INDEX IF EXISTS ch02_c.products_created, ch02_c.apparel_color_size;
TRUNCATE ch02_c.products RESTART IDENTITY CASCADE;

INSERT INTO ch02_c.products OVERRIDING SYSTEM VALUE
SELECT id, kind, name, price, created_at FROM ch02_r.src ORDER BY id;
SELECT setval(pg_get_serial_sequence('ch02_c.products', 'id'),
              (SELECT max(id) FROM ch02_c.products));

INSERT INTO ch02_c.apparel
SELECT id, color, size, material, season, fit, sleeve_cm, length_cm, chest_cm,
       weight_g, pockets
FROM ch02_r.src WHERE kind = 'apparel' ORDER BY id;
INSERT INTO ch02_c.appliance
SELECT id, watt, voltage, warranty_months, width_mm, depth_mm, height_mm,
       weight_kg, noise_db, cord_cm, energy_rank
FROM ch02_r.src WHERE kind = 'appliance' ORDER BY id;
INSERT INTO ch02_c.book
SELECT id, author, isbn, pages, publisher, published_year, edition, series_no,
       thickness_mm, age_from, chapters
FROM ch02_r.src WHERE kind = 'book' ORDER BY id;

CREATE INDEX products_created ON ch02_c.products (created_at DESC);
CREATE INDEX apparel_color_size ON ch02_c.apparel (color, size);
VACUUM (ANALYZE) ch02_c.products, ch02_c.apparel, ch02_c.appliance, ch02_c.book;
