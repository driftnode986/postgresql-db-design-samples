-- 制約で防げない以上、定期的に検査する。全行の先頭列が 0 になること。
-- ルートから辿り着けない行を数える（輪の中の行は、ルートから辿れない）
WITH RECURSIVE reachable AS (
  SELECT id FROM ch04_a.nodes WHERE parent_id IS NULL
  UNION
  SELECT n.id FROM ch04_a.nodes n JOIN reachable r ON n.parent_id = r.id
)
SELECT count(*) AS unreachable
FROM ch04_a.nodes n
WHERE NOT EXISTS (SELECT 1 FROM reachable r WHERE r.id = n.id);
