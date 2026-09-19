-- run-as: book_owner
-- expect-error: 53200
-- 🔴 案C では、全社への変更を 1 つのトランザクションで実行できない。
--
-- 1 つのトランザクションが保持できるロックの数には上限がある
-- （max_locks_per_transaction × (max_connections + max_prepared_transactions)）。
-- 表ごとにロックを取るので、テナント数が増えるとこの上限に当たる。
--
-- ここでは、既にある 1,000 テナントに加えて新しいスキーマを作り続け、
-- どこで止まるかを見る。1 つのトランザクションにまとめているので、
-- 失敗すると全部が巻き戻る。
--
SHOW max_locks_per_transaction;
SHOW max_connections;

BEGIN;
DO $$
DECLARE
  i int;
BEGIN
  FOR i IN 2001..12000 LOOP
    EXECUTE format('CREATE SCHEMA ch13_c_x%s', lpad(i::text, 5, '0'));
    EXECUTE format('CREATE TABLE ch13_c_x%s.deals (id bigint PRIMARY KEY)',
                   lpad(i::text, 5, '0'));
    IF i % 500 = 0 THEN
      RAISE NOTICE 'created up to %', i;
    END IF;
  END LOOP;
END $$;
COMMIT;
