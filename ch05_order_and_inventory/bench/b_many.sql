-- 案B: 3 商品の一括引当。更新の順序は PostgreSQL が決める
\set p1 random(1, 50)
\set p2 random(1, 50)
\set p3 random(1, 50)
SELECT ch05_b.allocate_many(ARRAY[:p1, :p2, :p3]::bigint[], 1);
