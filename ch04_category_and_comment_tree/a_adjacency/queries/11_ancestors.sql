-- 先祖すべて（パンくず）。深さのぶんしか辿らない
EXPLAIN (ANALYZE)
WITH RECURSIVE a AS (
  SELECT id, parent_id FROM ch04_a.nodes WHERE id = 992336
  UNION ALL
  SELECT n.id, n.parent_id FROM ch04_a.nodes n JOIN a ON a.parent_id = n.id
)
SELECT count(*) FROM a;
