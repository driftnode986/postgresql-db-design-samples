-- 案B: 1 万商品への分散
\set pid random_zipfian(1, 10000, 1.1)
SELECT ch05_b.allocate(:pid, 1);
