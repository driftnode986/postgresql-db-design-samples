-- 案B の一覧。SQL に WHERE tenant_id は書かない。ポリシーが付ける。
-- 案A と同じテナント・同じ件数・同じ回数で測る。
--
-- run-as: book_app

-- 小さい会社
SELECT set_config('app.tenant_id', '50', false);
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_b.deals ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_b.deals ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_b.deals ORDER BY created_at DESC LIMIT 20;

-- 大きい会社
SELECT set_config('app.tenant_id', '1', false);
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_b.deals ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_b.deals ORDER BY created_at DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, title, amount, created_at
FROM ch13_b.deals ORDER BY created_at DESC LIMIT 20;

SELECT set_config('app.tenant_id', '50', false);
