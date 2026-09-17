-- 案C: 共通の項目を親テーブルに、種類ごとの項目を子テーブルに分ける。
-- 子テーブルの主キーは、親の id を指す外部キーを兼ねる
CREATE SCHEMA ch02_c;
CREATE TABLE ch02_c.products (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind        text        NOT NULL
              CHECK (kind IN ('apparel', 'appliance', 'book')),
  name        text        NOT NULL,
  price       int         NOT NULL CHECK (price >= 0),
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE ch02_c.apparel (
  product_id  bigint PRIMARY KEY REFERENCES ch02_c.products (id) ON DELETE CASCADE,
  color text NOT NULL, size text NOT NULL, material text NOT NULL,
  season text, fit text, sleeve_cm int, length_cm int, chest_cm int,
  weight_g int, pockets int
);
CREATE TABLE ch02_c.appliance (
  product_id  bigint PRIMARY KEY REFERENCES ch02_c.products (id) ON DELETE CASCADE,
  watt int NOT NULL, voltage int NOT NULL, warranty_months int NOT NULL,
  width_mm int, depth_mm int, height_mm int, weight_kg int,
  noise_db int, cord_cm int, energy_rank int
);
CREATE TABLE ch02_c.book (
  product_id  bigint PRIMARY KEY REFERENCES ch02_c.products (id) ON DELETE CASCADE,
  author text NOT NULL, isbn text NOT NULL, pages int NOT NULL,
  publisher text, published_year int, edition int, series_no int,
  thickness_mm int, age_from int, chapters int
);
