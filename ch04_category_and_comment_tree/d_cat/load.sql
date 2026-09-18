SELECT count(*) AS src_rows FROM ch04_r.src_cat \gset
SELECT CASE WHEN :src_rows = 0 THEN 1/0 ELSE 1 END AS source_must_not_be_empty;
\timing on
TRUNCATE ch04_d.b_paths;
TRUNCATE ch04_d.a_nodes, ch04_d.b_nodes, ch04_d.c_nodes CASCADE;

INSERT INTO ch04_d.a_nodes SELECT id, parent_id, name, pos FROM ch04_r.src_cat ORDER BY id;
INSERT INTO ch04_d.b_nodes SELECT id, parent_id, name, pos FROM ch04_r.src_cat ORDER BY id;
INSERT INTO ch04_d.c_nodes (id, parent_id, path, name, pos)
WITH RECURSIVE p AS (
  SELECT id, parent_id, name, pos, text2ltree(id::text) AS path
  FROM ch04_r.src_cat WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, c.parent_id, c.name, c.pos, p.path || text2ltree(c.id::text)
  FROM ch04_r.src_cat c JOIN p ON c.parent_id = p.id
)
SELECT id, parent_id, path, name, pos FROM p ORDER BY id;

INSERT INTO ch04_d.b_paths (ancestor_id, descendant_id, depth)
WITH RECURSIVE p(ancestor_id, descendant_id, depth) AS (
  SELECT id, id, 0 FROM ch04_d.b_nodes
  UNION ALL
  SELECT p.ancestor_id, n.id, p.depth + 1
  FROM p JOIN ch04_d.b_nodes n ON n.parent_id = p.descendant_id
)
SELECT ancestor_id, descendant_id, depth FROM p;

CREATE INDEX a_nodes_parent_idx ON ch04_d.a_nodes (parent_id, pos, id);
CREATE INDEX b_nodes_parent_idx ON ch04_d.b_nodes (parent_id, pos, id);
CREATE INDEX b_paths_desc_idx   ON ch04_d.b_paths (descendant_id, depth);
CREATE INDEX b_paths_child_idx  ON ch04_d.b_paths (ancestor_id, descendant_id) WHERE depth = 1;
CREATE INDEX c_nodes_path_gist  ON ch04_d.c_nodes USING gist (path);
CREATE INDEX c_nodes_parent_idx ON ch04_d.c_nodes (parent_id, pos, id);

ANALYZE ch04_d.a_nodes; ANALYZE ch04_d.b_nodes;
ANALYZE ch04_d.b_paths; ANALYZE ch04_d.c_nodes;
