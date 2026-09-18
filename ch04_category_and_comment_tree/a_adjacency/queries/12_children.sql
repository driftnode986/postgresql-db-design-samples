-- 直下の子だけ。親を指す列のインデックスをそのまま引く
EXPLAIN (ANALYZE)
SELECT id FROM ch04_a.nodes WHERE parent_id = 11 ORDER BY id;
