-- 横断用のインデックス (created_at) を足して、同じ問い合わせを測り直す。
-- インデックスのサイズも記録して、払う代償を示す。
--
-- run-as: book_owner
CREATE INDEX deals_created_a ON ch13_a.deals (created_at);
ANALYZE ch13_a.deals;

EXPLAIN (ANALYZE) SELECT count(*) FROM ch13_a.deals
WHERE created_at >= now() - interval '5 days' AND created_at < now();
EXPLAIN (ANALYZE) SELECT count(*) FROM ch13_a.deals
WHERE created_at >= now() - interval '5 days' AND created_at < now();
EXPLAIN (ANALYZE) SELECT count(*) FROM ch13_a.deals
WHERE created_at >= now() - interval '5 days' AND created_at < now();

-- 2 つのインデックスのサイズ
SELECT indexrelid::regclass AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE schemaname = 'ch13_a' AND relname = 'deals'
ORDER BY index_name;

-- 元に戻す。以降の測定に影響させない。
DROP INDEX ch13_a.deals_created_a;
