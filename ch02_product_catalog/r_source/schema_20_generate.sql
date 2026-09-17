-- 元データを作る。各案の load.sql より先に実行する。
-- SIZE=S は 10 万商品、M は 100 万商品
SELECT CASE :'size' WHEN 'S' THEN 100000 WHEN 'M' THEN 1000000 END AS n \gset
SELECT :n AS rows_to_load;   -- S・M 以外なら、ここで構文エラーになって止まる（何も消さない）

\timing on
TRUNCATE ch02_r.src;
DROP TABLE IF EXISTS ch02_r.draw;
SELECT setseed(0.42);

-- 1 商品につき乱数を 19 個引いて、作業用のテーブルに置く。
-- k は種類、c・s・m は必ず持つ属性、p1〜p7 は「その属性を持つか」、v1〜v7 はその値に使う
CREATE TABLE ch02_r.draw AS
SELECT g AS id,
       CASE WHEN k < 0.6 THEN 'apparel' WHEN k < 0.7 THEN 'appliance'
            ELSE 'book' END AS kind,
       100 * random(3, 300) AS price,
       '2024-01-01 00:00+09'::timestamptz + g * (interval '600 days' / :n)
         AS created_at,
       c, s, m, p1, p2, p3, p4, p5, p6, p7, v1, v2, v3, v4, v5, v6, v7
FROM (
  SELECT g, random() AS k, random() AS c, random() AS s, random() AS m,
         random() AS p1, random() AS p2, random() AS p3, random() AS p4,
         random() AS p5, random() AS p6, random() AS p7,
         random(0, 999) AS v1, random(0, 999) AS v2, random(0, 999) AS v3,
         random(0, 999) AS v4, random(0, 999) AS v5, random(0, 999) AS v6,
         random(0, 999) AS v7
  FROM generate_series(1, :n) AS g
  ORDER BY g
) AS r;

-- 衣料（6 割）。色とサイズに偏りを付ける。black は衣料の 30%、teal は 0.5%。
-- M は 40%、XXS は 0.5%。season より後ろの 7 つは、3 割の商品だけが持つ
INSERT INTO ch02_r.src (id, kind, name, price, created_at, color, size, material,
  season, fit, sleeve_cm, length_cm, chest_cm, weight_g, pockets)
SELECT id, kind, kind || '-' || id, price, created_at,
       CASE WHEN c < 0.30 THEN 'black' WHEN c < 0.55 THEN 'white'
            WHEN c < 0.72 THEN 'navy'  WHEN c < 0.84 THEN 'gray'
            WHEN c < 0.92 THEN 'red'   WHEN c < 0.97 THEN 'green'
            WHEN c < 0.995 THEN 'yellow' ELSE 'teal' END,
       CASE WHEN s < 0.40 THEN 'M' WHEN s < 0.70 THEN 'L' WHEN s < 0.90 THEN 'S'
            WHEN s < 0.995 THEN 'XL' ELSE 'XXS' END,
       (ARRAY['cotton', 'polyester', 'wool', 'linen'])[1 + floor(m * 4)::int],
       CASE WHEN p1 < 0.3
            THEN (ARRAY['spring', 'summer', 'autumn', 'winter'])[1 + v1 % 4] END,
       CASE WHEN p2 < 0.3 THEN (ARRAY['slim', 'regular', 'loose'])[1 + v2 % 3] END,
       CASE WHEN p3 < 0.3 THEN 40 + v3 % 30 END,
       CASE WHEN p4 < 0.3 THEN 55 + v4 % 40 END,
       CASE WHEN p5 < 0.3 THEN 80 + v5 % 50 END,
       CASE WHEN p6 < 0.3 THEN 100 + v6 END,
       CASE WHEN p7 < 0.3 THEN v7 % 6 END
FROM ch02_r.draw WHERE kind = 'apparel' ORDER BY id;

-- 家電（1 割）
INSERT INTO ch02_r.src (id, kind, name, price, created_at, watt, voltage,
  warranty_months, width_mm, depth_mm, height_mm, weight_kg, noise_db, cord_cm,
  energy_rank)
SELECT id, kind, kind || '-' || id, price, created_at,
       10 * (1 + floor(c * 150)::int),
       CASE WHEN s < 0.9 THEN 100 ELSE 200 END,
       (ARRAY[6, 12, 24, 36])[1 + floor(m * 4)::int],
       CASE WHEN p1 < 0.3 THEN 100 + v1 END,
       CASE WHEN p2 < 0.3 THEN 100 + v2 END,
       CASE WHEN p3 < 0.3 THEN 100 + v3 END,
       CASE WHEN p4 < 0.3 THEN 1 + v4 % 60 END,
       CASE WHEN p5 < 0.3 THEN 20 + v5 % 50 END,
       CASE WHEN p6 < 0.3 THEN 100 + v6 % 200 END,
       CASE WHEN p7 < 0.3 THEN 1 + v7 % 5 END
FROM ch02_r.draw WHERE kind = 'appliance' ORDER BY id;

-- 書籍（3 割）。著者にも偏りを付ける（番号の小さい著者に集中する）
INSERT INTO ch02_r.src (id, kind, name, price, created_at, author, isbn, pages,
  publisher, published_year, edition, series_no, thickness_mm, age_from, chapters)
SELECT id, kind, kind || '-' || id, price, created_at,
       'author-' || (1 + floor(power(c, 3) * 5000)::int),
       '978' || lpad(id::text, 10, '0'),
       80 + floor(s * 600)::int,
       CASE WHEN p1 < 0.3 THEN 'publisher-' || (1 + v1 % 200) END,
       CASE WHEN p2 < 0.3 THEN 1990 + v2 % 37 END,
       CASE WHEN p3 < 0.3 THEN 1 + v3 % 5 END,
       CASE WHEN p4 < 0.3 THEN 1 + v4 % 30 END,
       CASE WHEN p5 < 0.3 THEN 5 + v5 % 40 END,
       CASE WHEN p6 < 0.3 THEN v6 % 16 END,
       CASE WHEN p7 < 0.3 THEN 3 + v7 % 20 END
FROM ch02_r.draw WHERE kind = 'book' ORDER BY id;

DROP TABLE ch02_r.draw;
ANALYZE ch02_r.src;
