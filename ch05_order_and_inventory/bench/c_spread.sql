-- 案C: 1 万商品への分散
\set pid random_zipfian(1, 10000, 1.1)
SELECT ch05_c.allocate(:pid, 1);
