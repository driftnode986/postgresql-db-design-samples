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
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT ch07_d.balance_of(:heavy_user);

\echo '=== 案C: 取引を全件合計する（取引の少ない会員） ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
SELECT coalesce(sum(CASE WHEN kind = 'grant' THEN amount ELSE -amount END), 0)
FROM ch07_c.point_txns WHERE user_id = :light_user;
