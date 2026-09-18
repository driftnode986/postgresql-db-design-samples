-- run-as: book_owner
-- 見積もりは、ANALYZE がテーブルから抜き取る標本で決まる。標本は毎回変わるので、
-- ANALYZE を 5 回繰り返し、3 つの条件の見積もりと、中くらいの頻度の値の実行計画の形を記録する。
-- 実行するのは EXPLAIN だけ（ANALYZE を付けない）なので、問い合わせは実行されない

-- 1 回目
ANALYZE ch02_c.products, ch02_c.apparel;
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'black' AND a.size = 'M';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'teal' AND a.size = 'XXS';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL'
  ORDER BY p.created_at DESC LIMIT 20;

-- 2 回目
ANALYZE ch02_c.products, ch02_c.apparel;
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'black' AND a.size = 'M';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'teal' AND a.size = 'XXS';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL'
  ORDER BY p.created_at DESC LIMIT 20;

-- 3 回目
ANALYZE ch02_c.products, ch02_c.apparel;
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'black' AND a.size = 'M';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'teal' AND a.size = 'XXS';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL'
  ORDER BY p.created_at DESC LIMIT 20;

-- 4 回目
ANALYZE ch02_c.products, ch02_c.apparel;
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'black' AND a.size = 'M';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'teal' AND a.size = 'XXS';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL'
  ORDER BY p.created_at DESC LIMIT 20;

-- 5 回目
ANALYZE ch02_c.products, ch02_c.apparel;
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'black' AND a.size = 'M';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'teal' AND a.size = 'XXS';
EXPLAIN SELECT p.id FROM apparel AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL'
  ORDER BY p.created_at DESC LIMIT 20;
