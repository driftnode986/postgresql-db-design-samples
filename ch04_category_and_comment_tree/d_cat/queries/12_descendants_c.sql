EXPLAIN (ANALYZE)
SELECT count(*) FROM ch04_d.c_nodes
WHERE path <@ (SELECT path FROM ch04_d.c_nodes WHERE id = 2) AND id <> 2;
