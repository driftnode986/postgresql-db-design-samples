-- 第13章の元データ。4 案（案A・案B・案C・案D）はここから同じ中身を写す。
--
-- 🔴 案ごとにデータを作り直すと、案の違いではなく乱数の違いを測ることになる。
--    元データを 1 回だけ作り、各案の load.sql が ORDER BY id で写す。
--
-- 元データが持つのは「テナント（会社）」「顧客」「案件」の 3 つだけである。
-- それを 1 つの表に tenant_id で混ぜるか（案A・案B）、会社ごとに
-- スキーマを分けるか（案C）、tenant_id でパーティションに分けるか（案D）は、各案が決める。
CREATE SCHEMA IF NOT EXISTS ch13_r;

DROP TABLE IF EXISTS ch13_r.src_deal;
DROP TABLE IF EXISTS ch13_r.src_customer;
DROP TABLE IF EXISTS ch13_r.src_tenant;

CREATE TABLE ch13_r.src_tenant (
  id      int  PRIMARY KEY,
  name    text NOT NULL,
  status  text NOT NULL DEFAULT 'active'
          CHECK (status IN ('active', 'terminated'))
);

-- 顧客。email は「全社で 1 つのアドレスは 1 件」という要件があるかどうかで
-- 一意制約の張り方が変わる。案B でその違いを測る。
CREATE TABLE ch13_r.src_customer (
  tenant_id int    NOT NULL REFERENCES ch13_r.src_tenant(id),
  id        bigint NOT NULL,
  email     text   NOT NULL,
  name      text   NOT NULL,
  PRIMARY KEY (tenant_id, id)
);

-- 案件。一覧は created_at の新しい順に 20 件。
CREATE TABLE ch13_r.src_deal (
  tenant_id   int         NOT NULL REFERENCES ch13_r.src_tenant(id),
  id          bigint      NOT NULL,
  customer_id bigint      NOT NULL,
  title       text        NOT NULL,
  amount      numeric(14,2) NOT NULL,
  created_at  timestamptz NOT NULL,
  PRIMARY KEY (tenant_id, id),
  FOREIGN KEY (tenant_id, customer_id)
    REFERENCES ch13_r.src_customer(tenant_id, id)
);
