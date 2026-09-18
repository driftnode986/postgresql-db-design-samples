-- 上の並びを実際に見る（先頭 6 件）
SELECT id, path FROM ch04_c.nodes WHERE parent_id = 11 ORDER BY path LIMIT 6;
