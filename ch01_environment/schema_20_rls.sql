-- テナントごとに見える行を絞るテーブル。どのロールで数えるかで、結果が変わることを確かめる
CREATE TABLE ch01.docs (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id  int  NOT NULL,
  title      text NOT NULL
);
ALTER TABLE ch01.docs ENABLE ROW LEVEL SECURITY;
CREATE POLICY docs_tenant ON ch01.docs
  USING (tenant_id = current_setting('app.tenant_id')::int);

INSERT INTO ch01.docs (tenant_id, title)
VALUES (1, '見積書'), (1, '請求書'), (2, '契約書');
