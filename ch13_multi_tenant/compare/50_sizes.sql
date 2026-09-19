-- 4 案のサイズと、カタログの大きさを比べる。
--
-- 🔴 データを変える実験より前に測る（第10章・第11章の教訓）。
-- 🔴 パーティション表は親が 0 を返すので、パーティションの合計を取る。
--
-- run-as: book_app
-- standalone

-- 案A・案B（1 つの表）
SELECT 'A' AS plan, 'deals' AS rel,
       pg_size_pretty(pg_relation_size('ch13_a.deals'))       AS heap,
       pg_size_pretty(pg_indexes_size('ch13_a.deals'))        AS indexes,
       pg_size_pretty(pg_total_relation_size('ch13_a.deals')) AS total
UNION ALL
SELECT 'B', 'deals',
       pg_size_pretty(pg_relation_size('ch13_b.deals')),
       pg_size_pretty(pg_indexes_size('ch13_b.deals')),
       pg_size_pretty(pg_total_relation_size('ch13_b.deals'));

-- 案C（1,000 スキーマの合計）
SELECT 'C' AS plan,
       count(*)                                  AS tables,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS total
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname LIKE 'ch13\_c\_t%' AND c.relkind = 'r';

-- 案D（パーティションの合計。親は 0 を返すので使わない）
SELECT 'D' AS plan,
       count(*)                                           AS partitions,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS total
FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
WHERE i.inhparent = 'ch13_d.deals'::regclass;

-- カタログの大きさ。案C はここが太る。
SELECT 'pg_class'     AS catalog,
       (SELECT count(*) FROM pg_class)     AS rows,
       pg_size_pretty(pg_total_relation_size('pg_class'))     AS size
UNION ALL
SELECT 'pg_attribute',
       (SELECT count(*) FROM pg_attribute),
       pg_size_pretty(pg_total_relation_size('pg_attribute'));

-- 図に使うバイト値。pg_size_pretty は人が読む形なので、
-- 図の生成に渡す数値は丸めていないバイトで出す。
SELECT 'A' AS plan_bytes, pg_total_relation_size('ch13_a.deals') AS bytes
UNION ALL
SELECT 'C', (SELECT sum(pg_total_relation_size(c.oid))::bigint
             FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
             WHERE n.nspname LIKE 'ch13\_c\_t%' AND c.relkind = 'r')
UNION ALL
SELECT 'D', (SELECT sum(pg_total_relation_size(c.oid))::bigint
             FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
             WHERE i.inhparent = 'ch13_d.deals'::regclass)
ORDER BY 1;
