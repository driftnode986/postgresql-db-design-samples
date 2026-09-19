-- run-as: book_app
-- 3 案が使うテーブルの合計を比べる。
--
-- 🔴 案ごとにテーブルの顔ぶれが違うので、案が使うものをすべて数える
--    （docs/measurement-rules.yml の sizes.compare_same_plan_scope）。
--    判定表だけを見ると、元データの写しを持つ案A・案B を不当に有利に見せる。
--
-- 🔴 サイズは実験の前に測る。change や drift の実験で行が増えたあとに測ると、
--    別のものを測ることになる（第10章で案A が 64 MB でなく 156 MB になった）。
WITH t AS (
  SELECT '案A: 都度たどる' AS plan, c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch12_a' AND c.relkind = 'r'
  UNION ALL
  SELECT '案B: 役割と権限を表に', c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch12_b' AND c.relkind = 'r'
     AND c.relname IN ('scopes','users','documents','memberships',
                       'roles','permissions','role_permissions')
  UNION ALL
  SELECT '案C: 判定を実体化', c.oid
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'ch12_c' AND c.relkind = 'r'
)
SELECT plan,
       pg_size_pretty(sum(pg_relation_size(oid)))       AS heap,
       pg_size_pretty(sum(pg_indexes_size(oid)))        AS indexes,
       pg_size_pretty(sum(pg_total_relation_size(oid))) AS total,
       sum(pg_total_relation_size(oid))                 AS total_bytes
  FROM t GROUP BY plan ORDER BY total_bytes;

\echo '=== 内訳（テーブルごと） ==='
SELECT n.nspname || '.' || c.relname AS tbl,
       pg_size_pretty(pg_relation_size(c.oid))       AS heap,
       pg_size_pretty(pg_indexes_size(c.oid))        AS indexes,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total,
       c.reltuples::bigint                           AS est_rows
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname IN ('ch12_a','ch12_b','ch12_c') AND c.relkind = 'r'
 ORDER BY pg_total_relation_size(c.oid) DESC;

\echo '=== 🔴 案C の判定表は元データの何倍か（この章の目玉） ==='
SELECT (SELECT count(*) FROM ch12_c.documents)        AS documents,
       (SELECT count(*) FROM ch12_c.users)            AS users,
       (SELECT count(*) FROM ch12_c.memberships)      AS memberships,
       (SELECT count(*) FROM ch12_c.effective_access) AS effective_access,
       round((SELECT count(*) FROM ch12_c.effective_access)::numeric
             / nullif((SELECT count(*) FROM ch12_c.documents), 0), 1) AS times_documents,
       pg_size_pretty(pg_total_relation_size('ch12_c.documents'))        AS documents_size,
       pg_size_pretty(pg_total_relation_size('ch12_c.effective_access')) AS effective_size;

\echo '=== 🔴 大きなチーム 1 つが判定表の何割を占めるか ==='
-- 「全員が入るチーム」があるかどうかが、この案の成否を決める。
WITH big AS (
  SELECT s.id,
         (SELECT count(*) FROM ch12_c.memberships m WHERE m.scope_id = s.id) AS members,
         (SELECT count(*) FROM ch12_c.documents d
            JOIN ch12_c.scopes p ON p.id = d.project_id
           WHERE p.parent_id = s.id)                                        AS docs_below
    FROM ch12_c.scopes s WHERE s.kind = 'team'
)
SELECT id AS scope_id, members, docs_below,
       members * docs_below AS rows_generated,
       round(100.0 * members * docs_below
             / nullif((SELECT count(*) FROM ch12_c.effective_access), 0), 1) AS pct_of_table
  FROM big ORDER BY rows_generated DESC LIMIT 3;
