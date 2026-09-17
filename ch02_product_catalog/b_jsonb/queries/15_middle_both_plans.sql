-- 案B の「中くらいの頻度の値を、新しい順に 20 件」には、実行計画の候補が 2 つある。
-- どちらが選ばれるかは見積もりの行数で変わるので、選択肢を 1 つずつ止めて、両方を測る。
-- SET LOCAL は、そのトランザクションの中だけで効く

-- 1. GIN インデックスで条件に合う商品を全部見つけてから、並べ替える
BEGIN;
SET LOCAL enable_indexscan = off;
EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE attrs @> '{"color": "yellow", "size": "XL"}'
ORDER BY created_at DESC
LIMIT 20;
ROLLBACK;

-- 2. 新しい順のインデックスをたどり、1 件ずつ条件を確かめる
BEGIN;
SET LOCAL enable_bitmapscan = off;
EXPLAIN (ANALYZE)
SELECT id, name, price, created_at
FROM products
WHERE attrs @> '{"color": "yellow", "size": "XL"}'
ORDER BY created_at DESC
LIMIT 20;
ROLLBACK;
