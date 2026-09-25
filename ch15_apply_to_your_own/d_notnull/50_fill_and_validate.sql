-- run-as: book_owner
-- 残った行を埋めてから、検査を通す
UPDATE ch15_d.users
   SET email = 'unknown' || id || '@example.invalid'
 WHERE email IS NULL;

ALTER TABLE ch15_d.users VALIDATE CONSTRAINT users_email_nn;

SELECT conname, convalidated
  FROM pg_constraint
 WHERE conrelid = 'ch15_d.users'::regclass AND contype = 'n';
