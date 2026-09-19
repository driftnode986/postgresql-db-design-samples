-- 内容の履歴を、案C（本体 + 履歴）と案D（範囲型 + WITHOUT OVERLAPS）で測る。
--
-- 測るのは 2 つ。
--   (1) 現在の内容 1 件の取得
--   (2) ある時点の全件の取得（「先月末時点で、その申請の内容がどうだったか」）
--
-- 🔴 案D には公平にインデックスを与えてある（idx_d_current と idx_d_valid_gist）。
--    与えないと現在値の取得が全体走査になり、案の性質ではなくインデックスの有無を測ってしまう
--    （ch09_verification.md §7-1）。与えたインデックスは本文に明記する。

\echo '=== (1) 現在の内容 1 件: 案C（本体を主キーで引く） ==='
EXPLAIN (ANALYZE) SELECT amount_yen, category_id, reason
FROM ch09_c.requests
WHERE id = 50000;

\echo '=== (1) 現在の内容 1 件: 案D（上限が無限の版を部分インデックスで引く） ==='
EXPLAIN (ANALYZE) SELECT amount_yen, category_id, reason
FROM ch09_d.revisions
WHERE request_id = 50000 AND upper_inf(valid);

\echo '=== (2) ある時点の全件: 案C（本体と履歴を合わせて最新の版を選び直す） ==='
EXPLAIN (ANALYZE)
WITH allver AS (
  SELECT id AS request_id, amount_yen, updated_at AS t FROM ch09_c.requests
  UNION ALL
  SELECT request_id, amount_yen, valid_from FROM ch09_c.request_history
)
SELECT count(*), sum(amount_yen) FROM (
  SELECT DISTINCT ON (request_id) request_id, amount_yen
  FROM allver
  WHERE t <= timestamptz '2025-01-01 00:00:00+09'
  ORDER BY request_id, t DESC
) s;

\echo '=== (2) ある時点の全件: 案D（GiST インデックスで該当する版だけを拾う） ==='
EXPLAIN (ANALYZE) SELECT count(*), sum(amount_yen)
FROM ch09_d.revisions
WHERE valid @> timestamptz '2025-01-01 00:00:00+09';

\echo '=== 両案が同じ答えを返すこと（先頭列が 0 なら正常） ==='
-- 🔴 検査は、上で測ったのと同じ形の問い合わせで書く。
--    入れ子の CTE に書き換えると、別の計画になって別の結果を返すことがある
--    （実際に 163 件の差が出た。原因は書き換えたこちら側にあった）。
WITH allver AS (
  SELECT id AS request_id, amount_yen, updated_at AS t FROM ch09_c.requests
  UNION ALL
  SELECT request_id, amount_yen, valid_from FROM ch09_c.request_history
),
c AS (
  SELECT count(*) AS n, sum(amount_yen) AS s FROM (
    SELECT DISTINCT ON (request_id) request_id, amount_yen
    FROM allver WHERE t <= timestamptz '2025-01-01 00:00:00+09'
    ORDER BY request_id, t DESC
  ) x
),
d AS (
  SELECT count(*) AS n, sum(amount_yen) AS s
  FROM ch09_d.revisions WHERE valid @> timestamptz '2025-01-01 00:00:00+09'
)
SELECT (SELECT n FROM c) - (SELECT n FROM d) AS asof_count_diff,
       (SELECT s FROM c) - (SELECT s FROM d) AS asof_sum_diff;

\echo '=== 時点を指定して返る件数（0 ではないこと＝空振りでないこと） ==='
SELECT count(*) AS rows_at_asof FROM ch09_d.revisions
WHERE valid @> timestamptz '2025-01-01 00:00:00+09';
