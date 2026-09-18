-- 消し込みの順序を「付与の古い順」にすると何が起きるかを、実データで示す。
--
-- 🔴 付与の順（FIFO）と期限の順（FEFO）は別物である。
--    付与が古いほど期限が近い、とは限らない（短期のキャンペーンで配ったポイントは、
--    あとから付与されて先に切れる）。
\timing on

-- 食い違いが実際に起きている会員の内訳を 1 人ぶん見る。
-- 付与された順に並べたとき、期限が単調に増えていない会員を選ぶ
SELECT user_id AS demo_user
FROM ch07_a.point_lots
WHERE remaining > 0 AND expires_at > now()
GROUP BY user_id
HAVING count(*) >= 3
   AND (array_agg(id ORDER BY granted_at)) <> (array_agg(id ORDER BY expires_at))
ORDER BY user_id LIMIT 1 \gset

\echo '=== この会員の生きているロット（付与の古い順に並べる） ==='
SELECT id, granted_at::date AS granted, expires_at::date AS expires, remaining
FROM ch07_a.point_lots
WHERE user_id = :demo_user AND remaining > 0 AND expires_at > now()
ORDER BY granted_at, id
LIMIT 5;

\echo '=== 同じロットを、期限の近い順に並べ直す ==='
SELECT id, granted_at::date AS granted, expires_at::date AS expires, remaining
FROM ch07_a.point_lots
WHERE user_id = :demo_user AND remaining > 0 AND expires_at > now()
ORDER BY expires_at, id
LIMIT 5;

-- 🔴 2 つの並びの先頭が違えば、どちらの順で消し込むかで、使われるポイントが変わる。
--    付与順で消すと、期限の近いポイントが手つかずで残り、やがて失効する。

\echo '=== 付与順（FIFO）で消すと、先に失効するポイントが残る ==='
WITH fifo AS (
  SELECT id, expires_at, remaining,
         row_number() OVER (ORDER BY granted_at, id) AS fifo_rank
  FROM ch07_a.point_lots
  WHERE user_id = :demo_user AND remaining > 0 AND expires_at > now()
), fefo AS (
  SELECT id, row_number() OVER (ORDER BY expires_at, id) AS fefo_rank
  FROM ch07_a.point_lots
  WHERE user_id = :demo_user AND remaining > 0 AND expires_at > now()
)
SELECT f.id,
       f.expires_at::date AS expires,
       f.fifo_rank,
       e.fefo_rank,
       CASE WHEN f.fifo_rank > e.fefo_rank THEN '期限は近いのに後回しになる' END AS note
FROM fifo AS f JOIN fefo AS e USING (id)
ORDER BY e.fefo_rank
LIMIT 5;

-- 食い違いのある会員が全体で何人いるか
SELECT count(*) AS users_where_order_differs
FROM (
  SELECT user_id
  FROM ch07_a.point_lots
  WHERE remaining > 0 AND expires_at > now()
  GROUP BY user_id
  HAVING count(*) > 1
     AND (array_agg(id ORDER BY granted_at)) <> (array_agg(id ORDER BY expires_at))
) AS t;
