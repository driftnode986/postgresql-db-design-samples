-- ノード 11 の部分木を、別の親（ノード 3）へ移す。
-- 部分木の全ノードについて、移動前の先祖との対を消し、移動後の先祖との対を作り直す。
\timing on
BEGIN;
-- 1. 部分木のノードと、その外側にある古い先祖との対を消す
DELETE FROM ch04_b.paths
WHERE descendant_id IN (SELECT descendant_id FROM ch04_b.paths WHERE ancestor_id = 11)
  AND ancestor_id NOT IN (SELECT descendant_id FROM ch04_b.paths WHERE ancestor_id = 11);

-- 2. 新しい親の先祖すべてと、部分木のノードすべての対を作る
INSERT INTO ch04_b.paths (ancestor_id, descendant_id, depth)
SELECT up.ancestor_id, dn.descendant_id, up.depth + dn.depth + 1
FROM ch04_b.paths up, ch04_b.paths dn
WHERE up.descendant_id = 3 AND dn.ancestor_id = 11;

-- 3. 親を指す列も直す
UPDATE ch04_b.nodes SET parent_id = 3 WHERE id = 11;

-- 4. 閉包が壊れていないことを確かめる（どちらも 0 になること）。
--    閉包テーブルで最も事故りやすいのがこの移動なので、戻す前に検算する。
SELECT count(*) AS depth1_mismatch FROM (
  (SELECT ancestor_id, descendant_id FROM ch04_b.paths WHERE depth = 1
   EXCEPT SELECT parent_id, id FROM ch04_b.nodes WHERE parent_id IS NOT NULL)
  UNION ALL
  (SELECT parent_id, id FROM ch04_b.nodes WHERE parent_id IS NOT NULL
   EXCEPT SELECT ancestor_id, descendant_id FROM ch04_b.paths WHERE depth = 1)) AS d;
WITH RECURSIVE rebuilt(a, d, dep) AS (
  SELECT id, id, 0 FROM ch04_b.nodes
  UNION ALL
  SELECT r.a, n.id, r.dep + 1 FROM rebuilt r JOIN ch04_b.nodes n ON n.parent_id = r.d
)
SELECT count(*) AS closure_mismatch FROM (
  (SELECT a, d, dep FROM rebuilt
   EXCEPT SELECT ancestor_id, descendant_id, depth FROM ch04_b.paths)
  UNION ALL
  (SELECT ancestor_id, descendant_id, depth FROM ch04_b.paths
   EXCEPT SELECT a, d, dep FROM rebuilt)) AS x;
ROLLBACK;
