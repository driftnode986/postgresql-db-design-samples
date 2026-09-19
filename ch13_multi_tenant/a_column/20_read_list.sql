-- 案A の一覧。アプリが WHERE tenant_id = ... を書く。
-- 小さい会社（50）と大きい会社（1）の両方で測る。各 3 回。
--
-- run-as: book_app

-- 小さい会社
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_a.deals WHERE tenant_id = 50 ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_a.deals WHERE tenant_id = 50 ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_a.deals WHERE tenant_id = 50 ORDER BY created_at DESC LIMIT 20;

-- 大きい会社
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_a.deals WHERE tenant_id = 1 ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_a.deals WHERE tenant_id = 1 ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_a.deals WHERE tenant_id = 1 ORDER BY created_at DESC LIMIT 20;
