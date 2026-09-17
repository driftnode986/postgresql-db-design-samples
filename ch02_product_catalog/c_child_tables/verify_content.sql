-- 検査: 案C の中身が元データと同じであること。どの行も、先頭の列が 0 なら合格
SELECT (count(*) = 0)::int AS src_is_empty FROM ch02_r.src;
-- 親と 3 つの子を結合して、元データと同じ列の並びに戻してから比べる
SELECT count(*) AS only_in_source
FROM (
  SELECT * FROM ch02_r.src
  EXCEPT
  SELECT p.id, p.kind, p.name, p.price, p.created_at,
         a.color, a.size, a.material, a.season, a.fit, a.sleeve_cm, a.length_cm,
         a.chest_cm, a.weight_g, a.pockets,
         e.watt, e.voltage, e.warranty_months, e.width_mm, e.depth_mm, e.height_mm,
         e.weight_kg, e.noise_db, e.cord_cm, e.energy_rank,
         b.author, b.isbn, b.pages, b.publisher, b.published_year, b.edition,
         b.series_no, b.thickness_mm, b.age_from, b.chapters
  FROM ch02_c.products AS p
  LEFT JOIN ch02_c.apparel   AS a ON a.product_id = p.id
  LEFT JOIN ch02_c.appliance AS e ON e.product_id = p.id
  LEFT JOIN ch02_c.book      AS b ON b.product_id = p.id
) AS d;
SELECT (SELECT count(*) FROM ch02_r.src) - (SELECT count(*) FROM ch02_c.products)
       AS row_count_diff;
-- 種類と違う子テーブルに行が入っていないこと
SELECT count(*) AS wrong_child
FROM ch02_c.products AS p
WHERE (p.kind <> 'apparel'   AND EXISTS (SELECT FROM ch02_c.apparel   WHERE product_id = p.id))
   OR (p.kind <> 'appliance' AND EXISTS (SELECT FROM ch02_c.appliance WHERE product_id = p.id))
   OR (p.kind <> 'book'      AND EXISTS (SELECT FROM ch02_c.book      WHERE product_id = p.id));
