-- 検査: 案B の中身が元データと同じであること。どの行も、先頭の列が 0 なら合格
SELECT (count(*) = 0)::int AS src_is_empty FROM ch02_r.src;
SELECT count(*) AS different_rows
FROM ch02_r.src AS s
FULL JOIN ch02_b.products AS p USING (id)
WHERE s.id IS NULL OR p.id IS NULL
   OR (s.kind, s.name, s.price, s.created_at) IS DISTINCT FROM
      (p.kind, p.name, p.price, p.created_at)
   OR p.attrs <> jsonb_strip_nulls(
        to_jsonb(s) - ARRAY['id', 'kind', 'name', 'price', 'created_at']);
