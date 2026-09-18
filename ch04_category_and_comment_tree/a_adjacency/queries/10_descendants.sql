-- 子孫すべての件数。親を指す列しかないので、段ごとにインデックスを引き直す
EXPLAIN (ANALYZE)
WITH RECURSIVE d AS (
  SELECT id FROM ch04_a.nodes WHERE id = 11
  UNION ALL
  SELECT n.id FROM ch04_a.nodes n JOIN d ON n.parent_id = d.id
)
SELECT count(*) FROM d;
