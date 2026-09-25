-- run-as: book_owner
-- standalone
--
-- 動いているテーブルに NOT NULL を足す。NOT VALID で全行の確認を後回しにする。
-- 🔴 「NOT VALID なら止まらない」は不正確。NOT VALID を足す側も
--    AccessExclusiveLock を取る。短いだけである。
CREATE SCHEMA IF NOT EXISTS ch14_z;
DROP TABLE IF EXISTS ch14_z.nn;
CREATE TABLE ch14_z.nn (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, v text);
INSERT INTO ch14_z.nn (v) SELECT 'x' FROM generate_series(1, 200000);

BEGIN;
ALTER TABLE ch14_z.nn ADD CONSTRAINT nn_v_notnull NOT NULL v NOT VALID;
SELECT mode AS lock_when_adding_not_valid FROM pg_locks
 WHERE relation = 'ch14_z.nn'::regclass AND pid = pg_backend_pid();
COMMIT;

BEGIN;
ALTER TABLE ch14_z.nn VALIDATE CONSTRAINT nn_v_notnull;
SELECT mode AS lock_when_validating FROM pg_locks
 WHERE relation = 'ch14_z.nn'::regclass AND pid = pg_backend_pid();
COMMIT;
