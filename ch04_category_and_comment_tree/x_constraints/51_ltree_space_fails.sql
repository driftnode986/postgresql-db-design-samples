-- expect-error: ltree syntax error
-- 空白はどのロケールでも使えない
SELECT 'camera lens'::ltree;
