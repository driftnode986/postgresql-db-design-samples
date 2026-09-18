-- 単一接続では 3 案の区別が付かない。
-- 在庫 100 個の商品 1 に、3 個の引当と 999 個の引当を順に試す。
-- 3 案とも同じ結果（true → 97、false → 97 のまま）を返す。

\echo '## 案A'
SELECT ch05_a.allocate(1, 3) AS allocated;
SELECT qty AS qty_after FROM ch05_a.inventory WHERE product_id = 1;
SELECT ch05_a.allocate(1, 999) AS allocated_too_many;
SELECT qty AS qty_still FROM ch05_a.inventory WHERE product_id = 1;

\echo '## 案B'
SELECT ch05_b.allocate(1, 3) AS allocated;
SELECT qty AS qty_after FROM ch05_b.inventory WHERE product_id = 1;
SELECT ch05_b.allocate(1, 999) AS allocated_too_many;
SELECT qty AS qty_still FROM ch05_b.inventory WHERE product_id = 1;

\echo '## 案C'
SELECT ch05_c.allocate(1, 3) AS allocated;
SELECT qty AS qty_after FROM ch05_c.available WHERE product_id = 1;
SELECT ch05_c.allocate(1, 999) AS allocated_too_many;
SELECT qty AS qty_still FROM ch05_c.available WHERE product_id = 1;
