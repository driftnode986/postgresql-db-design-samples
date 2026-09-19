-- run-as: book_owner
-- 状態の型を 3 通り作り、「値を 1 つ足す」ときに取るロックを比べる。
--
-- 🔴 この節の軸は手数（ミリ秒）ではなくロックである。
--    10 万行では 0.4〜8.7 ミリ秒の差しか出ず、その数字では設計を選べない。
--    行数が増えると差が出るのは、止まる時間のほうである（ch09_verification.md §3-2）。

\echo '=== 準備: 3 通りの表を作る ==='
DROP TABLE IF EXISTS ch09_a.t_check;
DROP TABLE IF EXISTS ch09_a.t_enum;
DROP TABLE IF EXISTS ch09_a.t_lookup;
DROP TABLE IF EXISTS ch09_a.lookup_statuses;
DROP TYPE  IF EXISTS ch09_a.status_enum;

CREATE TYPE ch09_a.status_enum AS ENUM ('draft','submitted','approved','rejected','paid');

CREATE TABLE ch09_a.t_enum (
  id bigint PRIMARY KEY, status ch09_a.status_enum NOT NULL);

CREATE TABLE ch09_a.t_check (
  id bigint PRIMARY KEY, status text NOT NULL,
  CONSTRAINT t_check_status CHECK (status IN ('draft','submitted','approved','rejected','paid')));

CREATE TABLE ch09_a.lookup_statuses (code text PRIMARY KEY, label text NOT NULL);
INSERT INTO ch09_a.lookup_statuses VALUES
  ('draft','下書き'),('submitted','申請中'),('approved','承認'),
  ('rejected','差戻し'),('paid','支払済み');

CREATE TABLE ch09_a.t_lookup (
  id bigint PRIMARY KEY, status text NOT NULL REFERENCES ch09_a.lookup_statuses(code));

-- 同じ行数を入れる
INSERT INTO ch09_a.t_enum SELECT id, status::ch09_a.status_enum FROM ch09_a.requests;
INSERT INTO ch09_a.t_check SELECT id, status FROM ch09_a.requests;
INSERT INTO ch09_a.t_lookup SELECT id, status FROM ch09_a.requests;

SELECT 'enum' AS t, count(*) FROM ch09_a.t_enum
UNION ALL SELECT 'check', count(*) FROM ch09_a.t_check
UNION ALL SELECT 'lookup', count(*) FROM ch09_a.t_lookup
ORDER BY 1;

\timing on

\echo '=== ENUM に値を足す: 取るロック ==='
BEGIN;
ALTER TYPE ch09_a.status_enum ADD VALUE 'cancelled' AFTER 'paid';
SELECT c.relname, l.locktype, l.mode
FROM pg_locks l LEFT JOIN pg_class c ON c.oid = l.relation
WHERE l.pid = pg_backend_pid() AND (c.relname IS NULL OR c.relname LIKE 't\_%')
ORDER BY c.relname NULLS LAST, l.mode;
COMMIT;

\echo '=== CHECK 制約を作り直す: 取るロック ==='
BEGIN;
ALTER TABLE ch09_a.t_check DROP CONSTRAINT t_check_status;
ALTER TABLE ch09_a.t_check ADD CONSTRAINT t_check_status
  CHECK (status IN ('draft','submitted','approved','rejected','paid','cancelled'));
SELECT c.relname, l.mode
FROM pg_locks l JOIN pg_class c ON c.oid = l.relation
WHERE l.pid = pg_backend_pid() AND c.relname = 't_check'
ORDER BY l.mode;
COMMIT;

\echo '=== 参照テーブルに 1 行入れる: 取るロック ==='
BEGIN;
INSERT INTO ch09_a.lookup_statuses VALUES ('cancelled','取消');
SELECT c.relname, l.mode
FROM pg_locks l JOIN pg_class c ON c.oid = l.relation
WHERE l.pid = pg_backend_pid() AND c.relname = 'lookup_statuses'
ORDER BY l.mode;
COMMIT;

\echo '=== 値を廃止する: ENUM は未実装（エラーになる: 0A000） ==='
DO $$
BEGIN
  EXECUTE 'ALTER TYPE ch09_a.status_enum DROP VALUE ''rejected''';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'SQLSTATE=%  MESSAGE=%', SQLSTATE, SQLERRM;
END $$;

\timing off
