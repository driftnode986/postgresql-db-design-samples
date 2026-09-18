-- 子孫すべての件数。主キーの前方一致 1 回で済む
EXPLAIN (ANALYZE)
SELECT count(*) FROM ch04_b.paths WHERE ancestor_id = 11 AND depth > 0;
