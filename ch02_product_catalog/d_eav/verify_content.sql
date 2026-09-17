-- 検査: 案D の中身が元データと同じであること。どの行も、先頭の列が 0 なら合格
SELECT (count(*) = 0)::int AS src_is_empty FROM ch02_r.src;
SELECT (SELECT count(*) FROM ch02_r.src) - (SELECT count(*) FROM ch02_d.products)
       AS row_count_diff;
-- 元データの NULL でない属性の数と、属性の行の数が同じ
SELECT (SELECT sum((SELECT count(*) FROM jsonb_object_keys(jsonb_strip_nulls(
          to_jsonb(s) - ARRAY['id', 'kind', 'name', 'price', 'created_at']))))
        FROM ch02_r.src AS s)
     - (SELECT count(*) FROM ch02_d.product_attributes) AS attribute_count_diff;
