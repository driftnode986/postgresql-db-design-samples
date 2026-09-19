-- 変更の手数: 案C（本体 + 履歴）から案D（範囲型 + WITHOUT OVERLAPS）へ移す。
--
-- 測るのは 4 点（measurement-rules.yml）。
--   SQL 文の数 / 既存テーブルを書き換えるか / 取るロック / 所要時間
--
-- 🔴 BEGIN … ROLLBACK で囲む。確定させると、後続の測定のサイズが変わる
--    （第1章で、足して消す操作を 3 回確定させたら本体が 50 MB → 57 MB に増えた）。

\timing on

\echo '=== 移す前の行数 ==='
SELECT (SELECT count(*) FROM ch09_c.requests)        AS c_body,
       (SELECT count(*) FROM ch09_c.request_history) AS c_history,
       (SELECT count(*) FROM ch09_d.revisions)       AS d_revisions;

\echo '=== 移す前の検査: 本体と履歴に同じ版が二重に無いこと（先頭列が 0 なら正常） ==='
-- 🔴 二重にあると、次の版の開始時刻が自分と同じになって空の範囲ができ、
--    WITHOUT OVERLAPS が「empty WITHOUT OVERLAPS value found」で弾く。
--    移す前にここで気づけるようにしておく。
SELECT count(*) AS dup_rev FROM (
  SELECT request_id, rev FROM (
    SELECT request_id, rev FROM ch09_c.request_history
    UNION ALL SELECT id, rev FROM ch09_c.requests
  ) a GROUP BY 1, 2 HAVING count(*) > 1
) d;

\echo '=== 移行（3 文）と、そのあいだに取っているロック ==='
BEGIN;

-- 文 1: 移行先の表を作る
CREATE TABLE ch09_d.revisions_new (
  request_id   bigint    NOT NULL,
  valid        tstzrange NOT NULL,
  rev          int       NOT NULL,
  amount_yen   int       NOT NULL,
  category_id  int       NOT NULL,
  reason       text      NOT NULL,
  edited_by    bigint    NOT NULL,
  PRIMARY KEY (request_id, valid WITHOUT OVERLAPS)
);

-- 文 2: 本体と履歴を合わせ、次の版の開始時刻を終わりにして 1 つのテーブルにまとめる
INSERT INTO ch09_d.revisions_new
  (request_id, valid, rev, amount_yen, category_id, reason, edited_by)
SELECT request_id,
       tstzrange(valid_from,
                 lead(valid_from) OVER (PARTITION BY request_id ORDER BY rev),
                 '[)'),
       rev, amount_yen, category_id, reason, edited_by
FROM (
  SELECT request_id, rev, amount_yen, category_id, reason, edited_by, valid_from
  FROM ch09_c.request_history
  UNION ALL
  SELECT id, rev, amount_yen, category_id, reason, edited_by, updated_at
  FROM ch09_c.requests
) all_versions
ORDER BY request_id, rev;

-- 文 3: 検査（先頭列が 0 なら正常）
SELECT count(*) AS migrated_diff FROM (
  SELECT request_id, rev, amount_yen FROM ch09_r.src_revision
  EXCEPT
  SELECT request_id, rev, amount_yen FROM ch09_d.revisions_new
) d;

\echo '--- この時点で取っているロック（移行元の表を止めていないか） ---'
SELECT c.relname, l.mode
FROM pg_locks l JOIN pg_class c ON c.oid = l.relation
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE l.pid = pg_backend_pid() AND n.nspname IN ('ch09_c','ch09_d') AND c.relkind = 'r'
ORDER BY c.relname, l.mode;

\echo '--- 移行元のテーブルが書き換わっていないこと（filenode が同じ） ---'
SELECT 'ch09_c.requests' AS t, pg_relation_filenode('ch09_c.requests') AS filenode
UNION ALL
SELECT 'ch09_c.request_history', pg_relation_filenode('ch09_c.request_history');

ROLLBACK;

\echo '=== 戻っていること（revisions_new が無い） ==='
SELECT count(*) AS leftover FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'ch09_d' AND c.relname = 'revisions_new';

\timing off
