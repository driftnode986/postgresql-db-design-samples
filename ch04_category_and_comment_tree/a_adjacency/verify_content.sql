-- 元データと同じ木が入っているか（全行の先頭列が 0 になること）
SELECT count(*) AS nodes_diff FROM (
  SELECT id, parent_id, body FROM ch04_a.nodes
  EXCEPT SELECT id, parent_id, body FROM ch04_r.src_thread) AS d;
SELECT count(*) AS rows_diff FROM (
  SELECT (SELECT count(*) FROM ch04_a.nodes)
       - (SELECT count(*) FROM ch04_r.src_thread) AS n) AS x WHERE n <> 0;
SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_was_empty
  FROM ch04_r.src_thread;
