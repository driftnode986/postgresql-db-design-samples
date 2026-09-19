-- 運営の管理画面。全社を横断して、期間で集計する。
-- tenant_id の条件が無いので、(tenant_id, created_at DESC) のインデックスの
-- 先頭列が指定されない形になる。
--
-- PostgreSQL 18 は、こういう問い合わせでも複合インデックスを使える（skip scan）。
-- 使われることと、それが速いかどうかは別なので、専用のインデックスと比べる。
--
-- run-as: book_app

-- (1) 複合インデックスしかない状態。各 3 回
EXPLAIN (ANALYZE) SELECT count(*) FROM ch13_a.deals
WHERE created_at >= now() - interval '5 days' AND created_at < now();
EXPLAIN (ANALYZE) SELECT count(*) FROM ch13_a.deals
WHERE created_at >= now() - interval '5 days' AND created_at < now();
EXPLAIN (ANALYZE) SELECT count(*) FROM ch13_a.deals
WHERE created_at >= now() - interval '5 days' AND created_at < now();
