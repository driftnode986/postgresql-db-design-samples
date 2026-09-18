-- 案A の付与と利用。
--
-- 🔴 利用の関数で最も大事なのは「引けた合計が要求額に届いたか」を検査することである。
--    CHECK (remaining >= 0) はロット 1 行ごとの制約なので、「合計が足りない」を捕まえない。
--    検査を落とすと、残高より多く使おうとしたとき、エラーにならず引ける分だけ引いて成功する。

CREATE FUNCTION ch07_a.grant_points(p_uid bigint, p_amt bigint, p_expires timestamptz)
RETURNS bigint LANGUAGE sql AS $$
  WITH t AS (
    INSERT INTO ch07_a.point_txns (user_id, kind, amount)
    VALUES (p_uid, 'grant', p_amt)
    RETURNING id
  ), l AS (
    INSERT INTO ch07_a.point_lots (user_id, granted, remaining, expires_at, granted_at)
    VALUES (p_uid, p_amt, p_amt, p_expires, now())
    RETURNING id
  )
  SELECT t.id FROM t, l;
$$;

-- 期限の近い順（FEFO）に消し込む。
-- 窓関数でロットの残りの累計を出し、必要分に届くまでのロットから引く量を決めて、1 文で引く。
CREATE FUNCTION ch07_a.use_points(p_uid bigint, p_amt bigint)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_txn_id bigint;
  v_taken  bigint;
BEGIN
  INSERT INTO ch07_a.point_txns (user_id, kind, amount)
  VALUES (p_uid, 'use', p_amt)
  RETURNING id INTO v_txn_id;

  WITH cand AS (
    -- 期限の近い順に並べ、自分より前のロットの残りの累計を持つ
    SELECT l.id, l.remaining,
           coalesce(sum(l.remaining) OVER (ORDER BY l.expires_at, l.id
             ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS before_sum
    FROM ch07_a.point_lots AS l
    WHERE l.user_id = p_uid AND l.remaining > 0 AND l.expires_at > now()
  ), pick AS (
    -- 前までの累計が要求額に届いていないロットだけが対象。
    -- そのロットから引く量は「残り」と「要求額のうちまだ埋まっていない分」の小さいほう
    SELECT c.id, least(c.remaining, p_amt - c.before_sum) AS take
    FROM cand AS c
    WHERE c.before_sum < p_amt
  ), upd AS (
    UPDATE ch07_a.point_lots AS l
    SET remaining = l.remaining - p.take
    FROM pick AS p
    WHERE l.id = p.id
    RETURNING l.id, p.take
  )
  INSERT INTO ch07_a.lot_consumptions (txn_id, lot_id, taken)
  SELECT v_txn_id, id, take FROM upd;

  SELECT coalesce(sum(taken), 0) INTO v_taken
  FROM ch07_a.lot_consumptions WHERE txn_id = v_txn_id;

  -- 🔴 この検査が本体。ロットごとの CHECK では「合計が足りない」を捕まえられない
  IF v_taken < p_amt THEN
    RAISE EXCEPTION 'insufficient points: wanted %, taken %', p_amt, v_taken
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN true;
EXCEPTION
  WHEN check_violation THEN
    RETURN false;
END $$;

-- 残高。ロットの残りを合計する
CREATE FUNCTION ch07_a.balance_of(p_uid bigint)
RETURNS bigint LANGUAGE sql STABLE AS $$
  SELECT coalesce(sum(remaining), 0)
  FROM ch07_a.point_lots
  WHERE user_id = p_uid AND remaining > 0 AND expires_at > now();
$$;

GRANT EXECUTE ON FUNCTION ch07_a.grant_points(bigint, bigint, timestamptz),
                          ch07_a.use_points(bigint, bigint),
                          ch07_a.balance_of(bigint) TO book_app;
