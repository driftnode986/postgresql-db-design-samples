-- 一覧「申請中を新しい順に 20 件」を、状態の 2 案で測る。
--
-- 案A: 状態の列 + 部分インデックス
-- 案B: 遷移の追記のみ。最新行を導出する素朴な書き方と、印を使う書き方の 2 通り
--
-- 🔴 3 回ずつ取り、Execution Time は中央値を使う（measurement-rules.yml）。
--    主張は時間ではなく、読んだバッファ数と実行計画の形に置く。

\echo '=== 案A: 状態の列 + 部分インデックス ==='
EXPLAIN (ANALYZE) SELECT r.id, r.applicant_id, r.created_at
FROM ch09_a.requests r
WHERE r.status = 'submitted'
ORDER BY r.created_at DESC, r.id DESC
LIMIT 20;

\echo '=== 案B-0: 採取した案の書き方（申請ごとに LATERAL で最新行を引く） ==='
EXPLAIN (ANALYZE) SELECT r.id, s.changed_at
FROM ch09_b.requests r
JOIN LATERAL (
  SELECT to_status, changed_at FROM ch09_b.transitions
  WHERE request_id = r.id ORDER BY changed_at DESC LIMIT 1
) s ON true
WHERE s.to_status = 'submitted'
ORDER BY s.changed_at DESC
LIMIT 20;

\echo '=== 案B-1: 遷移の最新行を導出する（印を使わない） ==='
EXPLAIN (ANALYZE) SELECT s.request_id, s.changed_at
FROM (
  SELECT DISTINCT ON (request_id) request_id, to_status, changed_at
  FROM ch09_b.transitions
  ORDER BY request_id, seq DESC
) s
WHERE s.to_status = 'submitted'
ORDER BY s.changed_at DESC
LIMIT 20;

\echo '=== 案B-2: 最新行の印を使う ==='
EXPLAIN (ANALYZE) SELECT t.request_id, t.changed_at
FROM ch09_b.transitions t
WHERE t.is_current AND t.to_status = 'submitted'
ORDER BY t.changed_at DESC
LIMIT 20;

\echo '=== 一覧のインデックスサイズ ==='
SELECT 'A: idx_a_submitted'        AS idx, pg_size_pretty(pg_relation_size('ch09_a.idx_a_submitted')) AS size
UNION ALL
SELECT 'B: idx_b_current_submitted',     pg_size_pretty(pg_relation_size('ch09_b.idx_b_current_submitted'))
UNION ALL
SELECT 'B: idx_b_to_status',             pg_size_pretty(pg_relation_size('ch09_b.idx_b_to_status'))
ORDER BY 1;

\echo '=== 3 案とも同じ 20 件を返すこと（先頭列が 0 なら正常） ==='
WITH a AS (
  SELECT r.id FROM ch09_a.requests r WHERE r.status = 'submitted'
  ORDER BY r.created_at DESC, r.id DESC LIMIT 20
),
b AS (
  SELECT t.request_id AS id FROM ch09_b.transitions t
  WHERE t.is_current AND t.to_status = 'submitted'
  ORDER BY t.changed_at DESC LIMIT 20
)
SELECT count(*) AS inbox_diff FROM (
  (SELECT id FROM a EXCEPT SELECT id FROM b)
  UNION ALL
  (SELECT id FROM b EXCEPT SELECT id FROM a)
) d;
