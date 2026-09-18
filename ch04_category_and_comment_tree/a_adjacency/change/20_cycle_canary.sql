-- 検査そのものを検査する。わざと輪を作り、検査が 0 以外を返すことを確かめる。
-- 0 件を返すだけの検査は、検査が働いていないのか違反が無いのか区別できない。
\timing on
BEGIN;
-- ノード 11 の親を、その子孫（ノード 11 の部分木の中の 1 つ）にして輪を作る
UPDATE ch04_a.nodes SET parent_id = (
  SELECT id FROM ch04_a.nodes WHERE parent_id = 11 ORDER BY id LIMIT 1)
WHERE id = 11;

WITH RECURSIVE reachable AS (
  SELECT id FROM ch04_a.nodes WHERE parent_id IS NULL
  UNION
  SELECT n.id FROM ch04_a.nodes n JOIN reachable r ON n.parent_id = r.id
)
SELECT count(*) AS unreachable_after_injecting_a_cycle
FROM ch04_a.nodes n
WHERE NOT EXISTS (SELECT 1 FROM reachable r WHERE r.id = n.id);
ROLLBACK;
