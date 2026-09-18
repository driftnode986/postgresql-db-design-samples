-- 案A: 1 万商品への分散。人気商品に偏らせる（均等な乱数では衝突が起きず、案の差が出ない）
\set pid random_zipfian(1, 10000, 1.1)
SELECT ch05_a.allocate(:pid, 1);
