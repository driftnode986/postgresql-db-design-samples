-- 案A: 3 商品の一括引当。ロックを商品 id の昇順に取る
\set p1 random(1, 50)
\set p2 random(1, 50)
\set p3 random(1, 50)
SELECT ch05_a.allocate_many(ARRAY[:p1, :p2, :p3]::bigint[], 1, true);
