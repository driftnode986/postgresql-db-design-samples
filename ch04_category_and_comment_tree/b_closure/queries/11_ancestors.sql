-- 先祖すべて（パンくず）。逆向きのインデックスを引く
EXPLAIN (ANALYZE)
SELECT count(*) FROM ch04_b.paths WHERE descendant_id = 992336 AND depth > 0;
