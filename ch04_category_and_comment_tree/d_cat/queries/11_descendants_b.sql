EXPLAIN (ANALYZE)
SELECT count(*) FROM ch04_d.b_paths WHERE ancestor_id = 2 AND depth > 0;
