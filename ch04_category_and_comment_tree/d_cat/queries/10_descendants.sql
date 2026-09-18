-- カテゴリ型（深さ 5）で、3 案の子孫取得を測る
EXPLAIN (ANALYZE)
WITH RECURSIVE d AS (
  SELECT id FROM ch04_d.a_nodes WHERE id = 2
  UNION ALL
  SELECT n.id FROM ch04_d.a_nodes n JOIN d ON n.parent_id = d.id
)
SELECT count(*) FROM d;
