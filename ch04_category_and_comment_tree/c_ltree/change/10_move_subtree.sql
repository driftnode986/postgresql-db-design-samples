-- ノード 11 の部分木を、別の親（ノード 3）へ移す。
-- 部分木の全ノードの経路を書き換える。
\timing on
BEGIN;
UPDATE ch04_c.nodes
SET path = (SELECT path FROM ch04_c.nodes WHERE id = 3)
           || subpath(path, nlevel((SELECT path FROM ch04_c.nodes WHERE id = 11)) - 1)
WHERE path <@ (SELECT path FROM ch04_c.nodes WHERE id = 11);

UPDATE ch04_c.nodes SET parent_id = 3 WHERE id = 11;
ROLLBACK;
