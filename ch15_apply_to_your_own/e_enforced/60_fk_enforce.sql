-- run-as: book_owner
-- 違反を消してから、外部キーを ENFORCED に戻す。100 万行を検査する時間を測る
DELETE FROM ch15_e.events_ne AS e
 WHERE NOT EXISTS (SELECT 1 FROM ch15_e.accounts AS a
                    WHERE a.id = e.account_id);
\timing on
ALTER TABLE ch15_e.events_ne
  ALTER CONSTRAINT events_ne_account_fk ENFORCED;
\timing off
SELECT conname, conenforced, convalidated
  FROM pg_constraint
 WHERE conrelid = 'ch15_e.events_ne'::regclass
 ORDER BY conname;
