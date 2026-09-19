-- 案B: 案A と同じ形に、行レベルセキュリティのポリシーを足す。
--
-- 案A との違いはポリシーだけである。列もインデックスも同じにしてあるので、
-- 測って出た差は、すべてポリシーによるものになる。
CREATE SCHEMA ch13_b;

CREATE TABLE ch13_b.tenants (
  id     int  PRIMARY KEY,
  name   text NOT NULL,
  status text NOT NULL DEFAULT 'active'
         CHECK (status IN ('active', 'terminated'))
);

CREATE TABLE ch13_b.customers (
  tenant_id int    NOT NULL REFERENCES ch13_b.tenants(id),
  id        bigint NOT NULL,
  email     text   NOT NULL,
  name      text   NOT NULL,
  PRIMARY KEY (tenant_id, id)
);

CREATE TABLE ch13_b.deals (
  tenant_id   int           NOT NULL REFERENCES ch13_b.tenants(id),
  id          bigint        NOT NULL,
  customer_id bigint        NOT NULL,
  title       text          NOT NULL,
  amount      numeric(14,2) NOT NULL,
  created_at  timestamptz   NOT NULL,
  PRIMARY KEY (tenant_id, id),
  FOREIGN KEY (tenant_id, customer_id)
    REFERENCES ch13_b.customers(tenant_id, id)
);
