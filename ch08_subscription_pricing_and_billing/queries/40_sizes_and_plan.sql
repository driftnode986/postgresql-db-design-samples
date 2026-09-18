-- 4 案の保存サイズと、月次請求の計算の実行計画。
--
-- サイズは「写しを持つと、どれだけ増えるか」を見る。
-- 実行計画は「版つきの料金表にすると、月次の計算が重くなるか」を見る。
\echo '--- 4 案の保存サイズ（明細 + 契約 + 料金表）---'
SELECT t AS plan_kind,
       pg_size_pretty(sum(pg_relation_size(c.oid)))      AS heap,
       pg_size_pretty(sum(pg_indexes_size(c.oid)))       AS indexes,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS total
FROM (VALUES ('A','ch08_a'),('B','ch08_b'),('C','ch08_c'),('D','ch08_d')) v(t, sch)
JOIN pg_namespace n ON n.nspname = v.sch
JOIN pg_class c ON c.relnamespace = n.oid AND c.relkind = 'r'
GROUP BY t ORDER BY t;

\echo '--- 請求明細のテーブルだけのサイズ（写した列のぶんが差になる）---'
-- 🔴 4 案すべてを出す。案D の値を案B から流用しない
--    （案D は案B の列に priced_on を足しているので、同じ値にはならない）。
SELECT 'A' AS plan_kind,
       pg_relation_size('ch08_a.invoice_lines') AS bytes,
       (SELECT count(*) FROM ch08_a.invoice_lines) AS lines
UNION ALL
SELECT 'B', pg_relation_size('ch08_b.invoice_lines'),
       (SELECT count(*) FROM ch08_b.invoice_lines)
UNION ALL
SELECT 'C', pg_relation_size('ch08_c.invoice_lines'),
       (SELECT count(*) FROM ch08_c.invoice_lines)
UNION ALL
SELECT 'D', pg_relation_size('ch08_d.invoice_lines'),
       (SELECT count(*) FROM ch08_d.invoice_lines)
ORDER BY 1;

\echo '--- 月次請求の計算の実行計画（案B。契約の期間 × 料金の版の結合）---'
EXPLAIN (ANALYZE)
SELECT s.id, p.name, COALESCE(s.grandfathered_yen, pr.price_yen) AS unit_yen,
       upper(s.period * daterange('2024-04-01','2024-05-01'))
         - lower(s.period * daterange('2024-04-01','2024-05-01')) AS charged_days
FROM ch08_b.subscriptions s
JOIN ch08_b.plans p ON p.id = s.plan_id
JOIN ch08_b.plan_prices pr
  ON pr.plan_id = s.plan_id
 AND pr.valid @> lower(s.period * daterange('2024-04-01','2024-05-01'))
WHERE s.period && daterange('2024-04-01','2024-05-01');
