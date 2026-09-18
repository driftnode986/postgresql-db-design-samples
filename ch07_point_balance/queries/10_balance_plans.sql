-- 残高照会の実行計画を 4 案で比べる。
--
-- 🔴 読むべきは時間ではなく形である。時間は環境で変わるが、
--    実行計画のノードの種類・読んだページ数（Buffers）・ワーカー数は変わらない。
--
-- 会員は「取引の多い会員」と「取引の少ない会員」の 2 人を選ぶ。
-- 同じ表の中で 1 人あたりの件数だけが違うので、件数の効果だけを見られる。
\timing on

-- 対象の会員を決める。取引の最も多い会員と、最も少ない会員
SELECT user_id AS heavy_user FROM ch07_c.point_txns
GROUP BY user_id ORDER BY count(*) DESC LIMIT 1 \gset
SELECT user_id AS light_user FROM ch07_c.point_txns
GROUP BY user_id ORDER BY count(*) ASC LIMIT 1 \gset

SELECT :heavy_user AS heavy_user,
       (SELECT count(*) FROM ch07_c.point_txns WHERE user_id = :heavy_user) AS heavy_txns,
       :light_user AS light_user,
       (SELECT count(*) FROM ch07_c.point_txns WHERE user_id = :light_user) AS light_txns;

\echo '=== 案A: ロットの残りを合計する（取引の多い会員） ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT coalesce(sum(remaining), 0) FROM ch07_a.point_lots
WHERE user_id = :heavy_user AND remaining > 0 AND expires_at > now();

\echo '=== 案B: 残高の列を 1 行読む（取引の多い会員） ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT balance FROM ch07_b.point_balances WHERE user_id = :heavy_user;

\echo '=== 案C: 取引を全件合計する（取引の多い会員） ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT coalesce(sum(CASE WHEN kind = 'grant' THEN amount ELSE -amount END), 0)
FROM ch07_c.point_txns WHERE user_id = :heavy_user;

\echo '=== 案D: 締め残高 + それ以降の取引（取引の多い会員） ==='
-- 🔴 ほかの 3 案と同じく、関数を呼ばずに素の SQL で測る。
--    関数呼び出しにすると中身が Result ノードに畳まれ、Buffers に計画の作成や
--    カタログの参照が混ざる。しかもセッションの状態で値が変わるので、案どうしを
--    比べられない（独立レビューで検出。関数呼び出しでは 99、素の SQL では 27）
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
WITH s AS (
  SELECT as_of_txn_id, balance FROM ch07_d.point_snapshots
  WHERE user_id = :heavy_user ORDER BY as_of_txn_id DESC LIMIT 1
)
SELECT coalesce((SELECT balance FROM s), 0)
     + coalesce((
         SELECT sum(CASE WHEN t.kind = 'grant' THEN t.amount ELSE -t.amount END)
         FROM ch07_d.point_txns AS t
         WHERE t.user_id = :heavy_user
           AND t.id > coalesce((SELECT as_of_txn_id FROM s), 0)
       ), 0);

\echo '=== 案C: 取引を全件合計する（取引の少ない会員） ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT coalesce(sum(CASE WHEN kind = 'grant' THEN amount ELSE -amount END), 0)
FROM ch07_c.point_txns WHERE user_id = :light_user;
