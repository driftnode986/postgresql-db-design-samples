-- 全社に列を 1 つ足す。案B は 1 回、案C はテナントの数だけ実行する。
--
-- 2 通りの列追加を測る。
--   (1) 定数の既定値を持つ列。11 以降は表を書き換えない
--   (2) 型の変更。全行を書き換える
--
-- run-as: book_owner
-- standalone
\timing on

-- (1-B) 案B: 1 つの表に 1 回
ALTER TABLE ch13_b.deals ADD COLUMN is_archived boolean NOT NULL DEFAULT false;

-- (1-C) 案C: 1,000 スキーマに 1 回ずつ
DO $$
DECLARE t record;
BEGIN
  FOR t IN SELECT schema_name FROM ch13_c.tenants ORDER BY id LOOP
    EXECUTE format('ALTER TABLE %I.deals ADD COLUMN is_archived boolean NOT NULL DEFAULT false',
                   t.schema_name);
  END LOOP;
END $$;

-- (2-B) 案B: 型の変更。全行を書き換える
ALTER TABLE ch13_b.deals ALTER COLUMN title TYPE varchar(200);

-- (2-C) 案C: 同じ変更を 1,000 スキーマに
DO $$
DECLARE t record;
BEGIN
  FOR t IN SELECT schema_name FROM ch13_c.tenants ORDER BY id LOOP
    EXECUTE format('ALTER TABLE %I.deals ALTER COLUMN title TYPE varchar(200)',
                   t.schema_name);
  END LOOP;
END $$;

\timing off

-- (1) が表を書き換えていないことを、ファイルノードで確かめる。
-- 列を足す前後で同じなら、表の実体は書き換わっていない。
SELECT 'ch13_b.deals' AS rel, pg_relation_filenode('ch13_b.deals') AS filenode;
