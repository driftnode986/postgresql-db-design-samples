-- テナント 1 社の解約。小さい会社（51）と大きい会社（1）の両方で測る。
--
-- 案B は DELETE、案C は DROP SCHEMA、案D は DETACH + DROP TABLE。
-- 時間だけでなく、そのあとに残るもの（不要になった行と、戻らない領域）も見る。
--
-- run-as: book_owner
-- standalone
--
-- 🔴 案B は FORCE ROW LEVEL SECURITY なので、所有者にもポリシーが適用される。
--    解約は「他社の行を消す」操作なので、ポリシーが付いたままでは実行できない。
--    運用では BYPASSRLS を持つ管理用のロールを用意するが、ここでは
--    測定のためにポリシーを外して時間を測る（外す操作自体は一瞬で終わる）。
ALTER TABLE ch13_b.deals     NO FORCE ROW LEVEL SECURITY;
ALTER TABLE ch13_b.customers NO FORCE ROW LEVEL SECURITY;

\timing on

-- 案B: 小さい会社
DELETE FROM ch13_b.deals     WHERE tenant_id = 51;
DELETE FROM ch13_b.customers WHERE tenant_id = 51;

-- 案B: 大きい会社
DELETE FROM ch13_b.deals     WHERE tenant_id = 1;
DELETE FROM ch13_b.customers WHERE tenant_id = 1;

-- 案C: 小さい会社
DROP SCHEMA ch13_c_t0051 CASCADE;

-- 案C: 大きい会社
DROP SCHEMA ch13_c_t0001 CASCADE;

-- 案D: 大きい会社（パーティションを外して落とす）
ALTER TABLE ch13_d.deals DETACH PARTITION ch13_d.deals_t1;
DROP TABLE ch13_d.deals_t1;

\timing off

-- 案B の後始末。DELETE したぶんは、すぐには領域が戻らない。
SELECT relname,
       n_live_tup, n_dead_tup,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_stat_user_tables
WHERE schemaname = 'ch13_b' AND relname IN ('deals', 'customers')
ORDER BY relname;

\timing on
VACUUM ch13_b.deals;
\timing off

SELECT relname,
       n_live_tup, n_dead_tup,
       pg_size_pretty(pg_total_relation_size(relid)) AS size_after_vacuum
FROM pg_stat_user_tables
WHERE schemaname = 'ch13_b' AND relname = 'deals';
