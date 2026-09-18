-- run-as: book_owner
-- 2 ノード以上の輪は CHECK では防げない（副問い合わせを書けないため）。
-- CHECK があっても、この UPDATE は通ってしまう。
UPDATE ch04_x.nodes SET parent_id = 3 WHERE id = 1;
SELECT id, parent_id FROM ch04_x.nodes ORDER BY id;

-- 素朴な再帰 CTE は、この状態では止まらない。CYCLE 句を付けると止まる
WITH RECURSIVE d AS (
  SELECT id, parent_id FROM ch04_x.nodes WHERE id = 1
  UNION ALL
  SELECT n.id, n.parent_id FROM ch04_x.nodes n JOIN d ON n.parent_id = d.id
) CYCLE id SET is_cycle USING path
SELECT id, parent_id, is_cycle FROM d;
