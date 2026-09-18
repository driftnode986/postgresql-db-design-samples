-- 案D の残高。最新の締め残高を 1 行引き、それ以降の取引だけを合計して足す
CREATE FUNCTION ch07_d.balance_of(p_uid bigint)
RETURNS bigint LANGUAGE sql STABLE AS $$
  WITH s AS (
    SELECT as_of_txn_id, balance
    FROM ch07_d.point_snapshots
    WHERE user_id = p_uid
    ORDER BY as_of_txn_id DESC
    LIMIT 1
  )
  SELECT coalesce((SELECT balance FROM s), 0)
       + coalesce((
           SELECT sum(CASE WHEN t.kind = 'grant' THEN t.amount ELSE -t.amount END)
           FROM ch07_d.point_txns AS t
           WHERE t.user_id = p_uid
             AND t.id > coalesce((SELECT as_of_txn_id FROM s), 0)
         ), 0);
$$;

GRANT EXECUTE ON FUNCTION ch07_d.balance_of(bigint) TO book_app;
