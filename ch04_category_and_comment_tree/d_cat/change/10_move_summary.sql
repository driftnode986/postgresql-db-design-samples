-- run-as: book_owner
-- カテゴリ型（深さ 5）で、3 案の「部分木の移動」を続けて測る。
-- 深さ 20 のスレッド型と同じ操作を、浅い木で測って結論が変わるかを見る。
-- ノード 2（配下 1,995 件）を、別の親（ノード 3）の下へ移す。すべて ROLLBACK で戻す。
\timing on

-- 案A
BEGIN;
UPDATE ch04_d.a_nodes SET parent_id = 3 WHERE id = 2;
ROLLBACK;

-- 案B
BEGIN;
DELETE FROM ch04_d.b_paths
WHERE descendant_id IN (SELECT descendant_id FROM ch04_d.b_paths WHERE ancestor_id = 2)
  AND ancestor_id NOT IN (SELECT descendant_id FROM ch04_d.b_paths WHERE ancestor_id = 2);
INSERT INTO ch04_d.b_paths (ancestor_id, descendant_id, depth)
SELECT up.ancestor_id, dn.descendant_id, up.depth + dn.depth + 1
FROM ch04_d.b_paths up, ch04_d.b_paths dn
WHERE up.descendant_id = 3 AND dn.ancestor_id = 2;
UPDATE ch04_d.b_nodes SET parent_id = 3 WHERE id = 2;
ROLLBACK;

-- 案C
BEGIN;
UPDATE ch04_d.c_nodes
SET path = (SELECT path FROM ch04_d.c_nodes WHERE id = 3)
           || subpath(path, nlevel((SELECT path FROM ch04_d.c_nodes WHERE id = 2)) - 1)
WHERE path <@ (SELECT path FROM ch04_d.c_nodes WHERE id = 2);
UPDATE ch04_d.c_nodes SET parent_id = 3 WHERE id = 2;
ROLLBACK;
