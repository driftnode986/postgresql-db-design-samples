-- 直下の子だけ。経路ではなく親を指す列で引く（経路のインデックスより速い）
EXPLAIN (ANALYZE)
SELECT id FROM ch04_c.nodes WHERE parent_id = 11 ORDER BY id;
