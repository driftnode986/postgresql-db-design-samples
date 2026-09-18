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
ROLLBACK;
