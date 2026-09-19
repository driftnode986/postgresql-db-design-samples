-- 案A: tenant_id の列を持ち、絞り込みをアプリが書く。
--
-- 主キーを (tenant_id, id) の複合にし、外部キーにも tenant_id を含める。
-- こうすると「A 社の案件が B 社の顧客を参照する」という行を、
-- データベースが受け付けない。アプリのバグでも混ざらない。
CREATE SCHEMA ch13_a;

CREATE TABLE ch13_a.tenants (
  id     int  PRIMARY KEY,
  name   text NOT NULL,
  status text NOT NULL DEFAULT 'active'
         CHECK (status IN ('active', 'terminated'))
);

CREATE TABLE ch13_a.customers (
  tenant_id int    NOT NULL REFERENCES ch13_a.tenants(id),
  id        bigint NOT NULL,
  email     text   NOT NULL,
  name      text   NOT NULL,
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE ch13_a.deals (
  tenant_id   int           NOT NULL REFERENCES ch13_a.tenants(id),
  id          bigint        NOT NULL,
  customer_id bigint        NOT NULL,
  title       text          NOT NULL,
  amount      numeric(14,2) NOT NULL,
  created_at  timestamptz   NOT NULL,
  PRIMARY KEY (tenant_id, id),
  FOREIGN KEY (tenant_id, customer_id)
    REFERENCES ch13_a.customers(tenant_id, id)
);
