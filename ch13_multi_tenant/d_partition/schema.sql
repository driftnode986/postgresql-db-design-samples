-- 案D: 案B と同じ形に、tenant_id でのパーティション分けを足す。
--
-- 全社に 1 つずつパーティションを作るのではなく、
-- 大きい会社だけを専用のパーティションにし、残りをまとめる。
-- こうするとパーティションの数が増えないので、計画の作成が遅くならない。
--
-- 🔴 パーティション分けの鍵（tenant_id）を主キーに含める必要がある。
--    案A・案B も (tenant_id, id) にしてあるので、主キーの形は 4 案でそろう。
CREATE SCHEMA ch13_d;

CREATE TABLE ch13_d.tenants (
  id     int  PRIMARY KEY,
  name   text NOT NULL,
  status text NOT NULL DEFAULT 'active'
         CHECK (status IN ('active', 'terminated'))
);

CREATE TABLE ch13_d.deals (
  tenant_id   int           NOT NULL,
  id          bigint        NOT NULL,
  customer_id bigint        NOT NULL,
  title       text          NOT NULL,
  amount      numeric(14,2) NOT NULL,
  created_at  timestamptz   NOT NULL,
  PRIMARY KEY (tenant_id, id)
) PARTITION BY LIST (tenant_id);

-- 大きい会社は専用のパーティションにする
CREATE TABLE ch13_d.deals_t1 PARTITION OF ch13_d.deals FOR VALUES IN (1);
-- 残りはまとめる
CREATE TABLE ch13_d.deals_rest PARTITION OF ch13_d.deals DEFAULT;
