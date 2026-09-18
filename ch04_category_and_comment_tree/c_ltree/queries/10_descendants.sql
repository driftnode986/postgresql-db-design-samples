-- 子孫すべての件数。経路の前方一致を GiST で引く
EXPLAIN (ANALYZE)
SELECT count(*) FROM ch04_c.nodes
WHERE path <@ (SELECT path FROM ch04_c.nodes WHERE id = 11) AND id <> 11;
