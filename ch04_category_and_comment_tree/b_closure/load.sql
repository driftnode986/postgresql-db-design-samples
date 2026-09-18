-- 元データを写し、閉包（先祖と子孫のすべての対）を組み立てる
SELECT count(*) AS src_rows FROM ch04_r.src_thread \gset
SELECT CASE WHEN :src_rows = 0
            THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch04_b.paths;
TRUNCATE ch04_b.nodes RESTART IDENTITY CASCADE;
DROP INDEX IF EXISTS ch04_b.nodes_parent_idx;
DROP INDEX IF EXISTS ch04_b.paths_desc_idx;
DROP INDEX IF EXISTS ch04_b.paths_child_idx;

INSERT INTO ch04_b.nodes (id, parent_id, body, pos)
OVERRIDING SYSTEM VALUE
SELECT id, parent_id, body, pos FROM ch04_r.src_thread ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch04_b.nodes', 'id'),
              (SELECT max(id) FROM ch04_b.nodes));

-- 閉包を 1 文で作る。行数は「ノード数 × 平均の深さ」になる
INSERT INTO ch04_b.paths (ancestor_id, descendant_id, depth)
WITH RECURSIVE p(ancestor_id, descendant_id, depth) AS (
  SELECT id, id, 0 FROM ch04_b.nodes
  UNION ALL
  SELECT p.ancestor_id, n.id, p.depth + 1
  FROM p JOIN ch04_b.nodes n ON n.parent_id = p.descendant_id
)
SELECT ancestor_id, descendant_id, depth FROM p;

CREATE INDEX nodes_parent_idx ON ch04_b.nodes (parent_id, pos, id);
-- 先祖をたどる（パンくず）用。主キーは先祖から子孫へ向きなので、逆向きに 1 本要る
CREATE INDEX paths_desc_idx ON ch04_b.paths (descendant_id, depth);
-- 直下の子だけを引く用。主キーには depth が入っていないので、これが無いと
-- 子孫を全部読んでから depth = 1 で絞ることになる
CREATE INDEX paths_child_idx ON ch04_b.paths (ancestor_id, descendant_id)
  WHERE depth = 1;

ANALYZE ch04_b.nodes;
ANALYZE ch04_b.paths;
