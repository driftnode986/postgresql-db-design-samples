-- 元データを作る。各案の load.sql より先に実行する
-- SIZE=S は 10 万商品、M は 100 万商品
SELECT CASE :'size' WHEN 'S' THEN 100000 WHEN 'M' THEN 1000000 END AS n \gset
SELECT :n AS rows_to_load;   -- S・M 以外なら、ここで構文エラーになって止まる（何も消さない）

\timing on
TRUNCATE ch02_r.src;
SELECT setseed(0.42);

-- 1 商品につき乱数を 19 個引く。k が種類、c・s・m が主な属性、p1〜p7 が「その属性を持つか」、
-- v1〜v7 が値。OFFSET 0 は、乱数を引く副問い合わせを外側の式に展開させないための指定
INSERT INTO ch02_r.src
SELECT g,
       kind,
       kind || '-' || g,
       100 * random(3, 300),
       '2024-01-01 00:00+09'::timestamptz + g * (interval '600 days' / :n),
       -- 衣料。色とサイズに偏りを付ける（black 30% … teal 0.5%、M 40% … XXS 0.5%）
       CASE WHEN kind = 'apparel' THEN
         CASE WHEN c < 0.30 THEN 'black' WHEN c < 0.55 THEN 'white'
              WHEN c < 0.72 THEN 'navy'  WHEN c < 0.84 THEN 'gray'
              WHEN c < 0.92 THEN 'red'   WHEN c < 0.97 THEN 'green'
              WHEN c < 0.995 THEN 'yellow' ELSE 'teal' END END,
       CASE WHEN kind = 'apparel' THEN
         CASE WHEN s < 0.40 THEN 'M' WHEN s < 0.70 THEN 'L' WHEN s < 0.90 THEN 'S'
              WHEN s < 0.995 THEN 'XL' ELSE 'XXS' END END,
       CASE WHEN kind = 'apparel' THEN
         (ARRAY['cotton','polyester','wool','linen'])[1 + floor(m * 4)::int] END,
       CASE WHEN kind = 'apparel' AND p1 < 0.3 THEN
         (ARRAY['spring','summer','autumn','winter'])[1 + v1 % 4] END,
       CASE WHEN kind = 'apparel' AND p2 < 0.3 THEN
         (ARRAY['slim','regular','loose'])[1 + v2 % 3] END,
       CASE WHEN kind = 'apparel' AND p3 < 0.3 THEN 40 + v3 % 30 END,
       CASE WHEN kind = 'apparel' AND p4 < 0.3 THEN 55 + v4 % 40 END,
       CASE WHEN kind = 'apparel' AND p5 < 0.3 THEN 80 + v5 % 50 END,
       CASE WHEN kind = 'apparel' AND p6 < 0.3 THEN 100 + v6 END,
       CASE WHEN kind = 'apparel' AND p7 < 0.3 THEN v7 % 6 END,
       -- 家電
       CASE WHEN kind = 'appliance' THEN 10 * (1 + floor(c * 150)::int) END,
       CASE WHEN kind = 'appliance' THEN CASE WHEN s < 0.9 THEN 100 ELSE 200 END END,
       CASE WHEN kind = 'appliance' THEN (ARRAY[6,12,24,36])[1 + floor(m * 4)::int] END,
       CASE WHEN kind = 'appliance' AND p1 < 0.3 THEN 100 + v1 END,
       CASE WHEN kind = 'appliance' AND p2 < 0.3 THEN 100 + v2 END,
       CASE WHEN kind = 'appliance' AND p3 < 0.3 THEN 100 + v3 END,
       CASE WHEN kind = 'appliance' AND p4 < 0.3 THEN 1 + v4 % 60 END,
       CASE WHEN kind = 'appliance' AND p5 < 0.3 THEN 20 + v5 % 50 END,
       CASE WHEN kind = 'appliance' AND p6 < 0.3 THEN 100 + v6 % 200 END,
       CASE WHEN kind = 'appliance' AND p7 < 0.3 THEN 1 + v7 % 5 END,
       -- 書籍
       CASE WHEN kind = 'book' THEN 'author-' || (1 + floor(power(c, 3) * 5000)::int) END,
       CASE WHEN kind = 'book' THEN '978' || lpad(g::text, 10, '0') END,
       CASE WHEN kind = 'book' THEN 80 + floor(s * 600)::int END,
       CASE WHEN kind = 'book' AND p1 < 0.3 THEN 'publisher-' || (1 + v1 % 200) END,
       CASE WHEN kind = 'book' AND p2 < 0.3 THEN 1990 + v2 % 37 END,
       CASE WHEN kind = 'book' AND p3 < 0.3 THEN 1 + v3 % 5 END,
       CASE WHEN kind = 'book' AND p4 < 0.3 THEN 1 + v4 % 30 END,
       CASE WHEN kind = 'book' AND p5 < 0.3 THEN 5 + v5 % 40 END,
       CASE WHEN kind = 'book' AND p6 < 0.3 THEN v6 % 16 END,
       CASE WHEN kind = 'book' AND p7 < 0.3 THEN 3 + v7 % 20 END
FROM (
  SELECT g,
         CASE WHEN k < 0.6 THEN 'apparel' WHEN k < 0.7 THEN 'appliance'
              ELSE 'book' END AS kind,
         c, s, m, p1, p2, p3, p4, p5, p6, p7, v1, v2, v3, v4, v5, v6, v7
  FROM (
    SELECT g, random() AS k, random() AS c, random() AS s, random() AS m,
           random() AS p1, random() AS p2, random() AS p3, random() AS p4,
           random() AS p5, random() AS p6, random() AS p7,
           random(0, 999) AS v1, random(0, 999) AS v2, random(0, 999) AS v3,
           random(0, 999) AS v4, random(0, 999) AS v5, random(0, 999) AS v6,
           random(0, 999) AS v7
    FROM generate_series(1, :n) AS g
    OFFSET 0
  ) AS r
) AS t
ORDER BY g;
ANALYZE ch02_r.src;
