-- 案A で運用を始めたあとに、経路の列（案C の形）を足す手順と時間。
-- 測ったあとは ROLLBACK で戻す。
\timing on
BEGIN;
-- 既定値を付けないので、表は書き換えられない（一瞬で終わる）
ALTER TABLE ch04_a.nodes ADD COLUMN path ltree;

-- 全行の経路を組み立てて埋める。ここが時間の大半を占める
WITH RECURSIVE p AS (
  SELECT id, text2ltree(id::text) AS path
  FROM ch04_a.nodes WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, p.path || text2ltree(c.id::text)
  FROM ch04_a.nodes c JOIN p ON c.parent_id = p.id
)
UPDATE ch04_a.nodes n SET path = p.path FROM p WHERE p.id = n.id;

-- 最後に NOT NULL を付ける（全行の検査が入る）
ALTER TABLE ch04_a.nodes ALTER COLUMN path SET NOT NULL;
ROLLBACK;
