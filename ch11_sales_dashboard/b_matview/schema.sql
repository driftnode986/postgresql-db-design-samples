-- 案B: マテリアライズドビューに集計を保存し、REFRESH で作り直す。
--
-- 元データの写しは案A と同じ。その上にマテリアライズドビューを載せる。
CREATE SCHEMA IF NOT EXISTS ch11_b;

DROP MATERIALIZED VIEW IF EXISTS ch11_b.daily_sales;
DROP TABLE IF EXISTS ch11_b.returns;
DROP TABLE IF EXISTS ch11_b.order_lines;

CREATE TABLE ch11_b.order_lines (
  id          bigint      PRIMARY KEY,
  order_id    bigint      NOT NULL,
  product_id  bigint      NOT NULL,
  category_id int         NOT NULL,
  qty         int         NOT NULL,
  amount_yen  bigint      NOT NULL,
  ordered_at  timestamptz NOT NULL
);

CREATE TABLE ch11_b.returns (
  id            bigint      PRIMARY KEY,
  order_line_id bigint      NOT NULL,
  sales_date    date        NOT NULL,
  returned_at   timestamptz NOT NULL,
  qty           int         NOT NULL,
  refund_yen    bigint      NOT NULL
);
