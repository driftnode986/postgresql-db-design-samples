-- 経路は文字列として辞書順に比較される。ラベルに id を入れると、投稿順にはならない。
-- 直下の返信を経路の順に並べると、100 が 92 より前に来る。
EXPLAIN (ANALYZE)
SELECT id, path FROM ch04_c.nodes WHERE parent_id = 11 ORDER BY path;
