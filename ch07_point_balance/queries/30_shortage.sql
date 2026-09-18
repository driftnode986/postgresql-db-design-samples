-- 🔴 「残高が足りないとき、消し込みはエラーにならず引ける分だけ引く」ことを示す。
--
-- CHECK (remaining >= 0) はロット 1 行ごとの制約なので、「合計が足りない」は捕まえない。
-- 呼び出し側で「引けた合計 = 要求額」を検査しないと、残高より多く使えてしまう。
--
-- 検査を持たない関数（use_points_no_check）と、持つ関数（use_points）を並べて比べる。
\timing on

-- 検査を持たない版を作る。本文で「これを書いてはいけない」と示すためのもの
CREATE OR REPLACE FUNCTION ch07_a.use_points_no_check(p_uid bigint, p_amt bigint)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v_txn_id bigint; v_taken bigint;
BEGIN
  INSERT INTO ch07_a.point_txns (user_id, kind, amount)
  VALUES (p_uid, 'use', p_amt) RETURNING id INTO v_txn_id;

  WITH cand AS (
    SELECT l.id, l.remaining,
           coalesce(sum(l.remaining) OVER (ORDER BY l.expires_at, l.id
             ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS before_sum
    FROM ch07_a.point_lots AS l
    WHERE l.user_id = p_uid AND l.remaining > 0 AND l.expires_at > now()
  ), pick AS (
    SELECT c.id, least(c.remaining, p_amt - c.before_sum) AS take
    FROM cand AS c WHERE c.before_sum < p_amt
  ), upd AS (
    UPDATE ch07_a.point_lots AS l SET remaining = l.remaining - p.take
    FROM pick AS p WHERE l.id = p.id
    RETURNING l.id, p.take
  )
  INSERT INTO ch07_a.lot_consumptions (txn_id, lot_id, taken)
  SELECT v_txn_id, id, take FROM upd;

  SELECT coalesce(sum(taken), 0) INTO v_taken
  FROM ch07_a.lot_consumptions WHERE txn_id = v_txn_id;
  RETURN v_taken;                 -- 🔴 検査せずに返す
END $$;

-- 残高の少ない会員を 1 人選ぶ
SELECT user_id AS poor_user FROM ch07_a.point_lots
WHERE remaining > 0 AND expires_at > now()
GROUP BY user_id ORDER BY sum(remaining) ASC LIMIT 1 \gset

SELECT :poor_user AS poor_user, ch07_a.balance_of(:poor_user) AS balance_before;

SELECT ch07_a.balance_of(:poor_user) * 10 AS wanted \gset

\echo '=== 検査を持たない版に、残高の 10 倍を要求する ==='
BEGIN;
-- 🔴 残高の確認は use_points_no_check とは別の文で行う。
--    同じ SELECT の中に並べると、balance_of は STABLE なので
--    文の開始時点の状態を読み、引いたあとの残高に見えない
SELECT coalesce(sum(remaining), 0) AS balance_before FROM ch07_a.point_lots
WHERE user_id = :poor_user AND remaining > 0 AND expires_at > now();

SELECT :wanted AS wanted, ch07_a.use_points_no_check(:poor_user, :wanted) AS taken;

SELECT coalesce(sum(remaining), 0) AS balance_after FROM ch07_a.point_lots
WHERE user_id = :poor_user AND remaining > 0 AND expires_at > now();
-- 🔴 エラーにならず、引ける分だけ引いて成功した。残高は 0 になり、
--    要求額との差（wanted - taken）はどこにも記録されずに消えた
ROLLBACK;

\echo '=== 検査を持つ版に、同じ要求をする ==='
BEGIN;
SELECT ch07_a.use_points(:poor_user, :wanted) AS succeeded;

SELECT coalesce(sum(remaining), 0) AS balance_after FROM ch07_a.point_lots
WHERE user_id = :poor_user AND remaining > 0 AND expires_at > now();
-- false が返り、残高は変わらない
ROLLBACK;
