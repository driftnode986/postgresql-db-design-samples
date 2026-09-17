-- 元データ。ここで 1 回だけ作り、各案の load.sql が id の順に写す。
-- 案ごとに乱数を引くと、案によって商品の中身が変わり、比べられなくなる。
CREATE SCHEMA IF NOT EXISTS ch02_r;
DROP TABLE IF EXISTS ch02_r.src;
CREATE TABLE ch02_r.src (
  id          bigint PRIMARY KEY,
  kind        text        NOT NULL,   -- apparel（衣料）/ appliance（家電）/ book（書籍）
  name        text        NOT NULL,
  price       int         NOT NULL,
  created_at  timestamptz NOT NULL,
  -- 衣料: 必ず持つ 3 つと、3 割の商品だけが持つ 7 つ
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
  thickness_mm int, age_from int, chapters int
);
