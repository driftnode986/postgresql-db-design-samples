-- 案C の残高。会員の取引を全部読んで合計する。
-- 取引が増えるほど読む行が増え、ある時点で実行計画の形が変わる（それを測るための案）
CREATE FUNCTION ch07_c.balance_of(p_uid bigint)
RETURNS bigint LANGUAGE sql STABLE AS $$
  SELECT coalesce(sum(CASE WHEN kind = 'grant' THEN amount ELSE -amount END), 0)
  FROM ch07_c.point_txns
  WHERE user_id = p_uid;
$$;

GRANT EXECUTE ON FUNCTION ch07_c.balance_of(bigint) TO book_app;
