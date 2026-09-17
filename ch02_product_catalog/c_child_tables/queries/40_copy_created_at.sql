-- run-as: book_owner
-- 案C で「絞り込んで新しい順に 20 件」を 1 つのインデックスで処理するには、
-- 並べ替えに使う created_at を子テーブルにも持たせる必要がある。
-- 写しを持った衣料のテーブルを別に作って確かめ、最後に ROLLBACK で消す
BEGIN;
CREATE TABLE ch02_c.apparel_copy AS
SELECT a.*, p.created_at
FROM ch02_c.apparel AS a JOIN ch02_c.products AS p ON p.id = a.product_id
ORDER BY a.product_id;
ALTER TABLE ch02_c.apparel_copy ADD PRIMARY KEY (product_id);
CREATE INDEX apparel_copy_color_size_created
  ON ch02_c.apparel_copy (color, size, created_at DESC);
ANALYZE ch02_c.apparel_copy;

EXPLAIN (ANALYZE)
SELECT p.id, p.name, p.price, p.created_at
FROM apparel_copy AS a
JOIN products AS p ON p.id = a.product_id
WHERE a.color = 'yellow' AND a.size = 'XL'
ORDER BY a.created_at DESC
LIMIT 20;
ROLLBACK;
