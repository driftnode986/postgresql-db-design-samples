-- 案A: 集計を保存せず、画面を開くたびに明細から数える。
--
-- テーブルは元データの写しだけで、集計のための入れ物を持たない。
-- 「鮮度」という観点では、この案だけが常に最新である。
CREATE SCHEMA IF NOT EXISTS ch11_a;

DROP TABLE IF EXISTS ch11_a.returns;
DROP TABLE IF EXISTS ch11_a.order_lines;

CREATE TABLE ch11_a.order_lines (
  id          bigint      PRIMARY KEY,
  order_id    bigint      NOT NULL,
  product_id  bigint      NOT NULL,
  category_id int         NOT NULL,
  qty         int         NOT NULL,
  amount_yen  bigint      NOT NULL,
  ordered_at  timestamptz NOT NULL
);

CREATE TABLE ch11_a.returns (
  id            bigint      PRIMARY KEY,
  order_line_id bigint      NOT NULL,
  sales_date    date        NOT NULL,
  returned_at   timestamptz NOT NULL,
  qty           int         NOT NULL,
  refund_yen    bigint      NOT NULL
);
