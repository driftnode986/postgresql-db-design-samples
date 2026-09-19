-- 3 案の保存の大きさ。
--
-- 🔴 案ごとに表の顔ぶれが違うので、案の合計で比べる。
--    案A は notifications だけ、案B は notifications + broadcasts + broadcast_reads、
--    案C は notifications + broadcasts + read_cursors。
--    1 つの表だけを比べると、案B・案C の別表を数え落として案A を不当に有利に見せる。
--
-- 🔴 パーティション表には pg_total_relation_size(親) を使わない（0 を返す）。
--    この章ではまだパーティションにしていないので、ここでは通常の取り方でよい。

\timing on

\echo '=== 案ごとの合計（本体・索引・合計） ==='
WITH t AS (
  SELECT '案A: 受信者ごとに行を作る' AS plan, c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch10_a' AND c.relkind = 'r'
  UNION ALL
  SELECT '案B: 告知は 1 行 + 既読の表', c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch10_b' AND c.relkind = 'r'
  UNION ALL
  SELECT '案C: 告知は 1 行 + カーソル', c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch10_c' AND c.relkind = 'r'
)
SELECT plan,
       pg_size_pretty(sum(pg_relation_size(oid)))       AS heap,
       pg_size_pretty(sum(pg_indexes_size(oid)))        AS indexes,
       pg_size_pretty(sum(pg_total_relation_size(oid))) AS total,
       sum(pg_total_relation_size(oid))                 AS total_bytes
  FROM t GROUP BY plan ORDER BY total_bytes;

\echo '=== 表ごとの内訳 ==='
SELECT n.nspname || '.' || c.relname                    AS tbl,
       pg_size_pretty(pg_relation_size(c.oid))          AS heap,
       pg_size_pretty(pg_indexes_size(c.oid))           AS indexes,
       pg_size_pretty(pg_total_relation_size(c.oid))    AS total,
       (SELECT reltuples::bigint FROM pg_class c2 WHERE c2.oid = c.oid) AS est_rows
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname IN ('ch10_a','ch10_b','ch10_c') AND c.relkind = 'r'
 ORDER BY n.nspname, pg_total_relation_size(c.oid) DESC;
