-- 案B の付与と利用。
--
-- 🔴 残高の更新と台帳の記録を 1 文で書く。PostgreSQL 18 の RETURNING old/new を使うと、
--    更新前と更新後の残高を同じ文から取れるので、あいだに別の SELECT を挟まずに済む。
--    17 以前は、更新前の値を別に読むか、トリガーで書くしかなかった。

-- 付与。初回は行が無いので ON CONFLICT で作る。
-- 🔴 挿入のとき old.balance は NULL になるので coalesce(old.balance, 0) が要る。
--    ここを落とすと、初回付与の台帳の balance_before が NULL で入る
CREATE FUNCTION ch07_b.grant_points(p_uid bigint, p_amt bigint, p_expires timestamptz)
RETURNS bigint LANGUAGE sql AS $$
  WITH up AS (
    INSERT INTO ch07_b.point_balances (user_id, balance)
    VALUES (p_uid, p_amt)
    ON CONFLICT (user_id)
      DO UPDATE SET balance = ch07_b.point_balances.balance + EXCLUDED.balance,
                    updated_at = now()
    RETURNING user_id, coalesce(old.balance, 0) AS before, new.balance AS after
  ), t AS (
    INSERT INTO ch07_b.point_txns
      (user_id, kind, amount, balance_before, balance_after)
    SELECT user_id, 'grant', p_amt, before, after FROM up
    RETURNING id
  )
  INSERT INTO ch07_b.point_lots (user_id, granted, remaining, expires_at, granted_at)
  VALUES (p_uid, p_amt, p_amt, p_expires, now())
  RETURNING id;
$$;

-- 利用。残高の列を減らし、同じ量をロットからも期限の近い順に引く。
-- 🔴 減らす量が 2 か所に書かれるので、両者が食い違わないことを関数の中で検査する
CREATE FUNCTION ch07_b.use_points(p_uid bigint, p_amt bigint)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_txn_id bigint;
  v_taken  bigint;
BEGIN
  -- 残高の列を減らし、更新前後をそのまま台帳へ書く。
  -- balance < p_amt なら CHECK (balance >= 0) が 23514 で弾く
  WITH up AS (
    UPDATE ch07_b.point_balances
    SET balance = balance - p_amt, updated_at = now()
    WHERE user_id = p_uid
    RETURNING user_id, old.balance AS before, new.balance AS after
  )
  INSERT INTO ch07_b.point_txns
    (user_id, kind, amount, balance_before, balance_after)
  SELECT user_id, 'use', p_amt, before, after FROM up
  RETURNING id INTO v_txn_id;

  IF v_txn_id IS NULL THEN
    RETURN false;            -- その会員の残高の行がまだ無い
  END IF;

  WITH cand AS (
    SELECT l.id, l.remaining,
           coalesce(sum(l.remaining) OVER (ORDER BY l.expires_at, l.id
             ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS before_sum
    FROM ch07_b.point_lots AS l
    WHERE l.user_id = p_uid AND l.remaining > 0 AND l.expires_at > now()
  ), pick AS (
    SELECT c.id, least(c.remaining, p_amt - c.before_sum) AS take
    FROM cand AS c
    WHERE c.before_sum < p_amt
  ), upd AS (
    UPDATE ch07_b.point_lots AS l
    SET remaining = l.remaining - p.take
    FROM pick AS p
    WHERE l.id = p.id
    RETURNING l.id, p.take
  )
  INSERT INTO ch07_b.lot_consumptions (txn_id, lot_id, taken)
  SELECT v_txn_id, id, take FROM upd;

  SELECT coalesce(sum(taken), 0) INTO v_taken
  FROM ch07_b.lot_consumptions WHERE txn_id = v_txn_id;

  -- 🔴 残高の列は足りていても、期限切れでロットが足りないことがある。
  --    その場合は残高の列だけが減って、ロットとの合計が食い違う。ここで止める
  IF v_taken < p_amt THEN
    RAISE EXCEPTION 'lot shortage: wanted %, taken %', p_amt, v_taken
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN true;
EXCEPTION
  WHEN check_violation THEN
    RETURN false;
END $$;

-- 残高。1 行を読むだけ
CREATE FUNCTION ch07_b.balance_of(p_uid bigint)
RETURNS bigint LANGUAGE sql STABLE AS $$
  SELECT coalesce((SELECT balance FROM ch07_b.point_balances WHERE user_id = p_uid), 0);
$$;

GRANT EXECUTE ON FUNCTION ch07_b.grant_points(bigint, bigint, timestamptz),
                          ch07_b.use_points(bigint, bigint),
                          ch07_b.balance_of(bigint) TO book_app;
