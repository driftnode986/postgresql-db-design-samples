-- 案C に会社ごとのスキーマを作り、元データを写す。
--
-- 1,000 テナントぶんのスキーマと表を作る。作成にかかる時間を測るため、
-- \timing を付けて実行する。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch13_r.src_deal) = 0 THEN
    RAISE EXCEPTION '元データ ch13_r.src_deal が空です。先に r_source/ を実行してください';
  END IF;
END $$;

TRUNCATE ch13_c.tenants;

INSERT INTO ch13_c.tenants (id, name, status, schema_name)
SELECT id, name, status, 'ch13_c_t' || lpad(id::text, 4, '0')
FROM ch13_r.src_tenant ORDER BY id;

-- スキーマと表を作り、その中に自分のテナントのデータだけを入れる。
-- 案A・案B と違い、表に tenant_id の列は無い（スキーマが表している）。
--
-- 🔴 会社ごとに 1 文ずつ実行する（\gexec）。
--    DO ブロックにまとめると 1 つのトランザクションになり、
--    958 テナント目で「out of shared memory」に当たって全部が巻き戻る
--    （1 つのトランザクションが保持できるロックの数に上限があるため）。
--    つまり案C は、1,000 テナントの初期構築すら 1 回の操作では行えない。
--    この上限そのものは 50_migration_atomicity_fails.sql で確かめる。
SELECT format('CREATE SCHEMA %I', schema_name) FROM ch13_c.tenants ORDER BY id \gexec

SELECT format($f$CREATE TABLE %I.customers (
  id bigint PRIMARY KEY, email text NOT NULL, name text NOT NULL)$f$, schema_name)
FROM ch13_c.tenants ORDER BY id \gexec

SELECT format($f$CREATE TABLE %I.deals (
  id bigint PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES %I.customers(id),
  title text NOT NULL, amount numeric(14,2) NOT NULL,
  created_at timestamptz NOT NULL)$f$, schema_name, schema_name)
FROM ch13_c.tenants ORDER BY id \gexec

SELECT format($f$INSERT INTO %I.customers (id, email, name)
  SELECT id, email, name FROM ch13_r.src_customer WHERE tenant_id = %s ORDER BY id$f$,
  schema_name, id)
FROM ch13_c.tenants ORDER BY id \gexec

SELECT format($f$INSERT INTO %I.deals (id, customer_id, title, amount, created_at)
  SELECT id, customer_id, title, amount, created_at FROM ch13_r.src_deal
  WHERE tenant_id = %s ORDER BY id$f$, schema_name, id)
FROM ch13_c.tenants ORDER BY id \gexec

SELECT format('CREATE INDEX ON %I.deals (created_at DESC)', schema_name)
FROM ch13_c.tenants ORDER BY id \gexec

SELECT count(*) AS schemas_created
FROM pg_namespace WHERE nspname LIKE 'ch13\_c\_t%';
