-- REPEATABLE READ で条件つき UPDATE を同時実行する。
-- 競合すると待つのではなく 40001（シリアライゼーション失敗）で落ちる。
-- pgbench はこれを number of serialization failures に数える。
\set pid random_zipfian(1, 50, 1.1)
BEGIN ISOLATION LEVEL REPEATABLE READ;
UPDATE ch05_b.inventory SET qty = qty - 1 WHERE product_id = :pid AND qty >= 1;
END;
