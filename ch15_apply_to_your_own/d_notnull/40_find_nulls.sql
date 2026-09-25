-- 残っている NULL を探す。検査を済ませていない制約は、計画を省略する根拠に使われない
EXPLAIN (ANALYZE)
SELECT id FROM ch15_d.users WHERE email IS NULL;
