-- 元データと同じ木が入っているか、経路が正しいか（全行の先頭列が 0 になること）
SELECT count(*) AS nodes_diff FROM (
  SELECT id, parent_id, body FROM ch04_c.nodes
  EXCEPT SELECT id, parent_id, body FROM ch04_r.src_thread) AS d;

-- 経路の末尾が自分の id であること
SELECT count(*) AS path_tail_mismatch FROM ch04_c.nodes
WHERE ltree2text(subpath(path, -1)) <> id::text;

-- 経路の長さが深さと一致すること
SELECT count(*) AS path_depth_mismatch
FROM ch04_c.nodes c JOIN ch04_r.src_thread s ON s.id = c.id
WHERE nlevel(c.path) <> s.depth;

-- 親の経路が、自分の経路の先頭部分になっていること
SELECT count(*) AS path_parent_mismatch
FROM ch04_c.nodes c JOIN ch04_c.nodes p ON p.id = c.parent_id
WHERE NOT (c.path <@ p.path);

SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_was_empty
  FROM ch04_r.src_thread;
