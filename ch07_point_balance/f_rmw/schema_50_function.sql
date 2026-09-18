-- 3 つの書き方を並べる。違うのは残高をどう増やすかだけで、台帳への記録は同じ。
--
--   add_naive     … 残高を読み、アプリ側で足して、その値を書き戻す（ロックなし）
--   add_forupdate … 同じことを SELECT ... FOR UPDATE で行をロックしてから行う（採取された案）
--   add_in_db     … UPDATE ... SET balance = balance + N（データベースの中で足す）
--
-- 🔴 どれも 1 接続では同じ結果になる。差が出るのは同時に実行したときだけである。

-- ロックなしで読んで書き戻す
CREATE FUNCTION ch07_f.add_naive(p_uid bigint, p_amt bigint)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_bal bigint;
BEGIN
  SELECT balance INTO v_bal FROM ch07_f.point_balances WHERE user_id = p_uid;
  -- 読んだ値をアプリ側で足して、その結果を「定数として」書き戻す。
  -- あいだに別の接続が確定させた更新は、この書き戻しで上書きされる
  UPDATE ch07_f.point_balances
  SET balance = v_bal + p_amt, updated_at = now()
  WHERE user_id = p_uid;
  INSERT INTO ch07_f.point_txns (user_id, amount) VALUES (p_uid, p_amt);
END $$;

-- 採取された案。行をロックしてから読む
CREATE FUNCTION ch07_f.add_forupdate(p_uid bigint, p_amt bigint)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_bal bigint;
BEGIN
  SELECT balance INTO v_bal FROM ch07_f.point_balances
  WHERE user_id = p_uid FOR UPDATE;
  UPDATE ch07_f.point_balances
  SET balance = v_bal + p_amt, updated_at = now()
  WHERE user_id = p_uid;
  INSERT INTO ch07_f.point_txns (user_id, amount) VALUES (p_uid, p_amt);
END $$;

-- データベースの中で足す
CREATE FUNCTION ch07_f.add_in_db(p_uid bigint, p_amt bigint)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE ch07_f.point_balances
  SET balance = balance + p_amt, updated_at = now()
  WHERE user_id = p_uid;
  INSERT INTO ch07_f.point_txns (user_id, amount) VALUES (p_uid, p_amt);
END $$;

GRANT EXECUTE ON FUNCTION ch07_f.add_naive(bigint, bigint),
                          ch07_f.add_forupdate(bigint, bigint),
                          ch07_f.add_in_db(bigint, bigint) TO book_app;
