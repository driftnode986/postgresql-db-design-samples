-- 元データと同じ木が入っているか、閉包が正しいか（全行の先頭列が 0 になること）
SELECT count(*) AS nodes_diff FROM (
  SELECT id, parent_id, body FROM ch04_b.nodes
  EXCEPT SELECT id, parent_id, body FROM ch04_r.src_thread) AS d;

-- 閉包の行数が「ノード数 × 平均の深さ」と一致すること
SELECT count(*) AS closure_row_mismatch FROM (
  SELECT (SELECT count(*) FROM ch04_b.paths) AS got,
         (SELECT sum(depth) FROM ch04_r.src_thread) AS want) AS x
WHERE got <> want;

-- depth = 1 の対が、親子関係とちょうど一致すること
SELECT count(*) AS depth1_diff FROM (
  (SELECT ancestor_id, descendant_id FROM ch04_b.paths WHERE depth = 1
   EXCEPT
   SELECT parent_id, id FROM ch04_b.nodes WHERE parent_id IS NOT NULL)
  UNION ALL
  (SELECT parent_id, id FROM ch04_b.nodes WHERE parent_id IS NOT NULL
   EXCEPT
   SELECT ancestor_id, descendant_id FROM ch04_b.paths WHERE depth = 1)) AS d;

SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_was_empty
  FROM ch04_r.src_thread;
