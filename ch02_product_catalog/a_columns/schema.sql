-- 案A: 属性ごとに列を足す。種類に関係のない列は NULL になる
CREATE SCHEMA ch02_a;
CREATE TABLE ch02_a.products (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind        text        NOT NULL
              CHECK (kind IN ('apparel', 'appliance', 'book')),
  name        text        NOT NULL,
  price       int         NOT NULL CHECK (price >= 0),
  created_at  timestamptz NOT NULL DEFAULT now(),
  -- 衣料
  color text, size text, material text,
  season text, fit text, sleeve_cm int, length_cm int, chest_cm int,
  weight_g int, pockets int,
  -- 家電
  watt int, voltage int, warranty_months int,
  width_mm int, depth_mm int, height_mm int, weight_kg int,
  noise_db int, cord_cm int, energy_rank int,
  -- 書籍
  author text, isbn text, pages int,
  publisher text, published_year int, edition int, series_no int,
  thickness_mm int, age_from int, chapters int,
  -- 種類ごとの必須の属性
  CONSTRAINT apparel_required CHECK (kind <> 'apparel'
    OR (color IS NOT NULL AND size IS NOT NULL AND material IS NOT NULL)),
  CONSTRAINT appliance_required CHECK (kind <> 'appliance'
    OR (watt IS NOT NULL AND voltage IS NOT NULL
        AND warranty_months IS NOT NULL)),
  CONSTRAINT book_required CHECK (kind <> 'book'
    OR (author IS NOT NULL AND isbn IS NOT NULL AND pages IS NOT NULL))
);
