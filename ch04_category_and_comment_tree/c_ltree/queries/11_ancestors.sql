-- 先祖すべて（パンくず）。自分の経路に含まれる id をそのまま読む
EXPLAIN (ANALYZE)
SELECT count(*) FROM ch04_c.nodes
WHERE path @> (SELECT path FROM ch04_c.nodes WHERE id = 992336) AND id <> 992336;
