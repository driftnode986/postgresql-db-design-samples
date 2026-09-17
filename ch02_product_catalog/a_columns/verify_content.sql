-- 検査: 案A の中身が元データと同じであること。どの行も、先頭の列が 0 なら合格
SELECT (count(*) = 0)::int AS src_is_empty FROM ch02_r.src;
SELECT count(*) AS only_in_source
FROM (SELECT * FROM ch02_r.src EXCEPT SELECT * FROM ch02_a.products) AS d;
SELECT count(*) AS only_in_plan
FROM (SELECT * FROM ch02_a.products EXCEPT SELECT * FROM ch02_r.src) AS d;
