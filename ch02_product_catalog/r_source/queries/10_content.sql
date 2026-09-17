-- 元データの内容を確かめる。content_hash は、同じ SIZE なら何度作り直しても同じ値になる
SELECT count(*) AS products,
       count(color) AS has_color, count(watt) AS has_watt, count(isbn) AS has_isbn,
       md5(string_agg(md5(s::text), '' ORDER BY id)) AS content_hash
FROM ch02_r.src AS s;

-- 色とサイズの偏り（衣料だけが持つ）
SELECT color, count(*) FROM ch02_r.src WHERE color IS NOT NULL
GROUP BY color ORDER BY count(*) DESC;
SELECT size, count(*) FROM ch02_r.src WHERE size IS NOT NULL
GROUP BY size ORDER BY count(*) DESC;

-- 比較に使う 3 つの条件に合う商品の数
SELECT count(*) FILTER (WHERE color = 'black'  AND size = 'M')   AS black_m,
       count(*) FILTER (WHERE color = 'yellow' AND size = 'XL')  AS yellow_xl,
       count(*) FILTER (WHERE color = 'teal'   AND size = 'XXS') AS teal_xxs
FROM ch02_r.src;
