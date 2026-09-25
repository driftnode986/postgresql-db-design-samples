-- run-as: book_owner
-- ENFORCED に戻す ALTER が取るロックを、トランザクションの中で見る。
-- 実行しても元に戻るように ROLLBACK で終える。
ALTER TABLE ch15_e.events_ne
  ALTER CONSTRAINT events_ne_account_fk NOT ENFORCED;

BEGIN;
ALTER TABLE ch15_e.events_ne
  ALTER CONSTRAINT events_ne_account_fk ENFORCED;
SELECT c.relname, l.mode
  FROM pg_locks AS l JOIN pg_class AS c ON c.oid = l.relation
 WHERE l.pid = pg_backend_pid()
   AND c.relname IN ('events_ne', 'accounts')
 ORDER BY c.relname, l.mode;
ROLLBACK;
