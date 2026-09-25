-- 検査が済むと、同じ問い合わせはテーブルを読まずに 0 行を返す
EXPLAIN (ANALYZE)
SELECT id FROM ch15_d.users WHERE email IS NULL;
