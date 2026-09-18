-- run-as: book_owner
-- 3 案の「部分木の移動」を続けて測り、1 つのログにまとめる。
-- 各案の change/10_move_subtree.sql と同じ文を、同じ順で実行する（すべて ROLLBACK で戻す）。
\timing on

-- 案A: 親を指す 1 行だけを書き換える
BEGIN;
UPDATE ch04_a.nodes SET parent_id = 3 WHERE id = 11;
ROLLBACK;

-- 案B: 部分木の全ノードについて、古い先祖との対を消し、新しい先祖との対を作る
BEGIN;
DELETE FROM ch04_b.paths
WHERE descendant_id IN (SELECT descendant_id FROM ch04_b.paths WHERE ancestor_id = 11)
  AND ancestor_id NOT IN (SELECT descendant_id FROM ch04_b.paths WHERE ancestor_id = 11);
INSERT INTO ch04_b.paths (ancestor_id, descendant_id, depth)
SELECT up.ancestor_id, dn.descendant_id, up.depth + dn.depth + 1
FROM ch04_b.paths up, ch04_b.paths dn
WHERE up.descendant_id = 3 AND dn.ancestor_id = 11;
UPDATE ch04_b.nodes SET parent_id = 3 WHERE id = 11;
ROLLBACK;

-- 案C: 部分木の全ノードの経路を書き換える
BEGIN;
UPDATE ch04_c.nodes
SET path = (SELECT path FROM ch04_c.nodes WHERE id = 3)
           || subpath(path, nlevel((SELECT path FROM ch04_c.nodes WHERE id = 11)) - 1)
WHERE path <@ (SELECT path FROM ch04_c.nodes WHERE id = 11);
UPDATE ch04_c.nodes SET parent_id = 3 WHERE id = 11;
ROLLBACK;
