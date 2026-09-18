-- 直下の子だけ。depth = 1 の部分インデックスを引く。
-- 3 案で同じものを測るため、返すのは子の id だけにする（並び順の列は持たない）。
EXPLAIN (ANALYZE)
SELECT descendant_id FROM ch04_b.paths
WHERE ancestor_id = 11 AND depth = 1
ORDER BY descendant_id;
