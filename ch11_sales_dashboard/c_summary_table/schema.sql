-- 案C: 集計テーブルを持ち、注文と同じトランザクションで差分更新する。
--
-- マテリアライズドビューと違い、ふつうのテーブルなので
-- 「その日その商品の行だけ」を書き換えられる。全体を作り直す必要がない。
CREATE SCHEMA IF NOT EXISTS ch11_c;

DROP TABLE IF EXISTS ch11_c.daily_sales;
DROP TABLE IF EXISTS ch11_c.returns;
DROP TABLE IF EXISTS ch11_c.order_lines;

CREATE TABLE ch11_c.order_lines (
  id          bigint      PRIMARY KEY,
  order_id    bigint      NOT NULL,
  product_id  bigint      NOT NULL,
  category_id int         NOT NULL,
  qty         int         NOT NULL,
  amount_yen  bigint      NOT NULL,
  ordered_at  timestamptz NOT NULL
);

CREATE TABLE ch11_c.returns (
  id            bigint      PRIMARY KEY,
  order_line_id bigint      NOT NULL,
  sales_date    date        NOT NULL,
  returned_at   timestamptz NOT NULL,
  qty           int         NOT NULL,
  refund_yen    bigint      NOT NULL
);

-- 集計テーブル。
--
-- 🔴 粒度（日別 × 商品別）を主キーにする。
--    あとから粒度を細かくするには元データからの再集計が要るので、
--    ここが「あとで変えるのが大変な点」になる。
CREATE TABLE ch11_c.daily_sales (
  sales_date  date   NOT NULL,
  product_id  bigint NOT NULL,
  category_id int    NOT NULL,
  qty         bigint NOT NULL DEFAULT 0,
  gross_yen   bigint NOT NULL DEFAULT 0,
  refund_yen  bigint NOT NULL DEFAULT 0,
  -- 🔴 net は保存生成列にする。gross と refund から必ず導けるので、
  --    別々に書き換えて食い違う余地をなくす（第10章の read_at と同じ原則）。
  --    18 では STORED / VIRTUAL を必ず書く（省くと VIRTUAL になる）。
  net_yen     bigint GENERATED ALWAYS AS (gross_yen - refund_yen) STORED,
  PRIMARY KEY (sales_date, product_id)
);
