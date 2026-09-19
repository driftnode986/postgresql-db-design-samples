-- run-as: book_app
-- 4 案が使うテーブルの合計を比べる。
--
-- 🔴 案ごとにテーブルの顔ぶれが違うので、案が使うものをすべて数える。
--    集計だけを比べると、元データの写しを持つ案を不当に有利に見せる。
--
-- 🔴 サイズは実験の前に測る。pgbench や drift の実験で行が増えたあとに測ると、
--    別のものを測ることになる（第10章で案A が 64 MB でなく 156 MB になった）。
WITH t AS (
  SELECT '案A: 都度集計'               AS plan, c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch11_a' AND c.relkind IN ('r', 'm')
     AND c.relname IN ('order_lines', 'returns')
  UNION ALL
  SELECT '案B: マテリアライズドビュー', c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch11_b' AND c.relkind IN ('r', 'm')
     AND c.relname IN ('order_lines', 'returns', 'daily_sales')
  UNION ALL
  SELECT '案C: 集計テーブル', c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch11_c' AND c.relkind IN ('r', 'm')
     AND c.relname IN ('order_lines', 'returns', 'daily_sales')
  UNION ALL
  SELECT '案D: 確定日 + 当日', c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch11_d' AND c.relkind IN ('r', 'm')
     AND c.relname IN ('order_lines', 'returns', 'daily_sales_final')
)
SELECT plan,
       pg_size_pretty(sum(pg_relation_size(oid)))        AS heap,
       pg_size_pretty(sum(pg_indexes_size(oid)))         AS indexes,
       pg_size_pretty(sum(pg_total_relation_size(oid)))  AS total,
       sum(pg_total_relation_size(oid))                  AS total_bytes
  FROM t GROUP BY plan ORDER BY total_bytes;

\echo '=== 内訳（テーブルごと） ==='
SELECT n.nspname || '.' || c.relname AS tbl,
       pg_size_pretty(pg_relation_size(c.oid))       AS heap,
       pg_size_pretty(pg_indexes_size(c.oid))        AS indexes,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total,
       c.reltuples::bigint                           AS est_rows
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname IN ('ch11_a','ch11_b','ch11_c','ch11_d')
   AND c.relkind IN ('r', 'm')
 ORDER BY 1;

\echo '=== 集計はどれだけ畳めるか（粒度ごとの行数） ==='
-- 🔴 集計表の効き目は「元データの行数」ではなく「粒度の組み合わせの数」で決まる。
SELECT (SELECT count(*) FROM ch11_a.order_lines)  AS src_rows,
       (SELECT count(*) FROM ch11_c.daily_sales)  AS by_date_product,
       (SELECT count(DISTINCT sales_date) FROM ch11_c.daily_sales) AS by_date;
