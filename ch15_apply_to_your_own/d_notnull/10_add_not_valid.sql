-- run-as: book_owner
-- 既存の行を検査せずに、NOT NULL を足す（18 から）
ALTER TABLE ch15_d.users
  ADD CONSTRAINT users_email_nn NOT NULL email NOT VALID;

SELECT conname, convalidated
  FROM pg_constraint
 WHERE conrelid = 'ch15_d.users'::regclass AND contype = 'n';
