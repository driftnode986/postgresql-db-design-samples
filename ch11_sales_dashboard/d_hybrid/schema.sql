-- 案D: 確定した日は集計テーブルから読み、当日だけ明細を都度集計して足す。
--
-- 案C との違いは「当日の行を集計テーブルに持たない」こと。
-- 当日は元データを数えるので、常に最新の値が出る。
-- そのかわり、読むたびに当日ぶんの明細を走査する。
CREATE SCHEMA IF NOT EXISTS ch11_d;

DROP TABLE IF EXISTS ch11_d.daily_sales_final;
DROP TABLE IF EXISTS ch11_d.returns;
DROP TABLE IF EXISTS ch11_d.order_lines;

CREATE TABLE ch11_d.order_lines (
  id          bigint      PRIMARY KEY,
  order_id    bigint      NOT NULL,
  product_id  bigint      NOT NULL,
  category_id int         NOT NULL,
  qty         int         NOT NULL,
  amount_yen  bigint      NOT NULL,
  ordered_at  timestamptz NOT NULL
);

CREATE TABLE ch11_d.returns (
  id            bigint      PRIMARY KEY,
  order_line_id bigint      NOT NULL,
  sales_date    date        NOT NULL,
  returned_at   timestamptz NOT NULL,
  qty           int         NOT NULL,
  refund_yen    bigint      NOT NULL
);

-- 確定した日だけを持つ集計テーブル。当日の行は入れない。
CREATE TABLE ch11_d.daily_sales_final (
  sales_date  date   NOT NULL,
  product_id  bigint NOT NULL,
  category_id int    NOT NULL,
  qty         bigint NOT NULL DEFAULT 0,
  gross_yen   bigint NOT NULL DEFAULT 0,
  refund_yen  bigint NOT NULL DEFAULT 0,
  net_yen     bigint GENERATED ALWAYS AS (gross_yen - refund_yen) STORED,
  PRIMARY KEY (sales_date, product_id)
);
