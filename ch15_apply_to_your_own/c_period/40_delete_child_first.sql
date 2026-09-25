-- run-as: book_owner
-- 料金の版を消すには、同じトランザクションで、参照している契約を先に消す。
-- 実行しても元に戻るように ROLLBACK で終える。
BEGIN;
DELETE FROM ch15_c.contracts WHERE plan_id = 1;
DELETE FROM ch15_c.plan_prices WHERE plan_id = 1;
ROLLBACK;
