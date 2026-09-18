-- 案B の検査。🔴 返す全行の先頭列が 0 であること
-- 🔴 案B の要は「残高の列」と「ロットの残り」の 2 か所が食い違わないことである。
--    案A には無い検査が要るのは、残高を置く場所が 2 つあるからである。
SELECT count(*) AS negative_balance FROM ch07_b.point_balances WHERE balance < 0;

SELECT count(*) AS negative_remaining FROM ch07_b.point_lots WHERE remaining < 0;

-- 残高の列と、ロットの残りの合計（期限切れも含む）の差。
-- 🔴 期限切れを含めて比べる。案B は失効の処理を回すまで期限切れを残高に数えているので、
--    期限内だけで比べると、失効していないのに「食い違っている」と読めてしまう
SELECT count(*) AS balance_vs_lots_drift
FROM (
  SELECT b.user_id
  FROM ch07_b.point_balances AS b
  LEFT JOIN (
    SELECT user_id, sum(remaining) AS remaining
    FROM ch07_b.point_lots GROUP BY user_id
  ) AS l ON l.user_id = b.user_id
  WHERE b.balance <> coalesce(l.remaining, 0)
) AS t;

-- 台帳に書いた更新後の残高が、前の取引の更新後の残高と amount で繋がっているか
SELECT count(*) AS ledger_chain_break
FROM (
  SELECT id FROM ch07_b.point_txns
  WHERE balance_before IS NOT NULL
    AND balance_after <> balance_before
        + CASE WHEN kind = 'grant' THEN amount ELSE -amount END
) AS t;

SELECT count(*) AS use_not_fully_taken
FROM (
  SELECT t.id
  FROM ch07_b.point_txns AS t
  LEFT JOIN (
    SELECT txn_id, sum(taken) AS taken FROM ch07_b.lot_consumptions GROUP BY txn_id
  ) AS c ON c.txn_id = t.id
  WHERE t.kind = 'use' AND coalesce(c.taken, 0) <> t.amount
) AS t;
