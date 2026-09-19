-- 4 案の保存サイズ。本体とインデックスを分けて出す。
--
-- 状態の 2 案（案A・案B）と、履歴の 2 案（案C・案D）は別の比較なので、合計も分けて出す。

\echo '=== 表ごとの内訳 ==='
SELECT n.nspname || '.' || c.relname                        AS "表",
       pg_size_pretty(pg_relation_size(c.oid))              AS "本体",
       pg_size_pretty(pg_indexes_size(c.oid))               AS "インデックス",
       pg_size_pretty(pg_total_relation_size(c.oid))        AS "合計",
       pg_relation_size(c.oid)                              AS body_bytes,
       pg_indexes_size(c.oid)                               AS index_bytes,
       pg_total_relation_size(c.oid)                        AS total_bytes
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('ch09_a','ch09_b','ch09_c','ch09_d')
  AND c.relkind = 'r'
  AND c.relname IN ('requests','transitions','request_history','revisions')
ORDER BY n.nspname, c.relname;

\echo '=== 状態の 2 案の合計（案A: 本体+遷移 / 案B: 本体+遷移） ==='
SELECT '案A: 状態の列 + 遷移履歴' AS "案",
       pg_size_pretty(pg_total_relation_size('ch09_a.requests')
                    + pg_total_relation_size('ch09_a.transitions')) AS "合計",
       pg_total_relation_size('ch09_a.requests')
     + pg_total_relation_size('ch09_a.transitions')                 AS total_bytes
UNION ALL
SELECT '案B: 遷移の追記のみ',
       pg_size_pretty(pg_total_relation_size('ch09_b.requests')
                    + pg_total_relation_size('ch09_b.transitions')),
       pg_total_relation_size('ch09_b.requests')
     + pg_total_relation_size('ch09_b.transitions')
ORDER BY total_bytes;

\echo '=== 状態の 2 案を、印つきの構成で比べる ==='
-- 🔴 案B の idx_b_to_status は「印を使わない書き方」のための索引である。
--    本書は印つきを勧めるので、それを除いた合計も出す。
--    除かずに比べると、勧めない構成の索引を案B の代償として示すことになる。
SELECT '案A: 状態の列 + 遷移履歴' AS "案",
       pg_size_pretty(pg_total_relation_size('ch09_a.requests')
                    + pg_total_relation_size('ch09_a.transitions')) AS "合計",
       pg_total_relation_size('ch09_a.requests')
     + pg_total_relation_size('ch09_a.transitions')                 AS total_bytes
UNION ALL
SELECT '案B: 印つき（to_status の索引を除く）',
       pg_size_pretty(pg_total_relation_size('ch09_b.requests')
                    + pg_total_relation_size('ch09_b.transitions')
                    - pg_relation_size('ch09_b.idx_b_to_status')),
       pg_total_relation_size('ch09_b.requests')
     + pg_total_relation_size('ch09_b.transitions')
     - pg_relation_size('ch09_b.idx_b_to_status')
UNION ALL
SELECT '案B: 印を使わない（to_status の索引を含む）',
       pg_size_pretty(pg_total_relation_size('ch09_b.requests')
                    + pg_total_relation_size('ch09_b.transitions')),
       pg_total_relation_size('ch09_b.requests')
     + pg_total_relation_size('ch09_b.transitions')
ORDER BY total_bytes;

\echo '=== 履歴の 2 案の合計（案C: 本体+履歴 / 案D: 版のみ） ==='
SELECT '案C: 本体 + 履歴' AS "案",
       pg_size_pretty(pg_total_relation_size('ch09_c.requests')
                    + pg_total_relation_size('ch09_c.request_history')) AS "合計",
       pg_total_relation_size('ch09_c.requests')
     + pg_total_relation_size('ch09_c.request_history')                 AS total_bytes
UNION ALL
SELECT '案D: 範囲型 + WITHOUT OVERLAPS',
       pg_size_pretty(pg_total_relation_size('ch09_d.requests')
                    + pg_total_relation_size('ch09_d.revisions')),
       pg_total_relation_size('ch09_d.requests')
     + pg_total_relation_size('ch09_d.revisions')
ORDER BY total_bytes;

\echo '=== インデックスごとのサイズ ==='
SELECT n.nspname || '.' || c.relname          AS "インデックス",
       pg_size_pretty(pg_relation_size(c.oid)) AS "サイズ",
       pg_relation_size(c.oid)                 AS bytes
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('ch09_a','ch09_b','ch09_c','ch09_d') AND c.relkind = 'i'
ORDER BY pg_relation_size(c.oid) DESC;
