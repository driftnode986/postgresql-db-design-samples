-- 第11章の元データ。4 案はここから同じ中身を写す。
--
-- 🔴 案ごとにデータを作り直すと、案の違いではなく乱数の違いを測ることになる。
--    元データを 1 回だけ作り、各案の load.sql が ORDER BY で写す。
--
-- 元データが持つのは「いつ・どの商品が・いくつ・いくらで売れたか」と
-- 「いつ・どれが返品されたか」だけである。
-- それを都度集計するか（案A）、マテリアライズドビューにするか（案B）、
-- 集計テーブルに持つか（案C）、確定日と当日で分けるか（案D）は、各案が決める。
CREATE SCHEMA IF NOT EXISTS ch11_r;

DROP TABLE IF EXISTS ch11_r.src_return;
DROP TABLE IF EXISTS ch11_r.src_order_line;
DROP TABLE IF EXISTS ch11_r.src_order;
DROP TABLE IF EXISTS ch11_r.src_product;

-- 商品。カテゴリはここに持つ
CREATE TABLE ch11_r.src_product (
  id          bigint PRIMARY KEY,
  name        text   NOT NULL,
  category_id int    NOT NULL
);

-- 注文
CREATE TABLE ch11_r.src_order (
  id         bigint      PRIMARY KEY,
  ordered_at timestamptz NOT NULL
);

CREATE INDEX src_order_ordered_at ON ch11_r.src_order (ordered_at);

-- 注文明細。
--
-- 🔴 category_id を明細に持たせる（商品マスタを見に行かない）。
--    商品のカテゴリがあとで変わっても、過去の集計が動かないようにするため。
--    採取した案のうち 3 本ともこの形にしていた（ch11_first_idea.md）。
--
-- 🔴 金額は整数（円）で持つ。本書の規約（金額は整数か numeric、money と
--    浮動小数点を使わない）にそろえる。
CREATE TABLE ch11_r.src_order_line (
  id          bigint      PRIMARY KEY,
  order_id    bigint      NOT NULL REFERENCES ch11_r.src_order(id),
  product_id  bigint      NOT NULL REFERENCES ch11_r.src_product(id),
  category_id int         NOT NULL,
  qty         int         NOT NULL,
  amount_yen  bigint      NOT NULL,
  ordered_at  timestamptz NOT NULL
);

CREATE INDEX src_order_line_ordered_at ON ch11_r.src_order_line (ordered_at);

-- 返品。
--
-- 🔴 明細を上書きせず、追記で持つ。sales_date は「元の注文日」で、
--    ここの売上が減る。上書きにすると「いつ返品されたか」が消え、
--    過去の日をあとから作り直すことしかできなくなる（第7章の案A と同じ対立）。
CREATE TABLE ch11_r.src_return (
  id            bigint      PRIMARY KEY,
  order_line_id bigint      NOT NULL REFERENCES ch11_r.src_order_line(id),
  sales_date    date        NOT NULL,   -- 元の注文日（この日の売上が減る）
  returned_at   timestamptz NOT NULL,
  qty           int         NOT NULL,
  refund_yen    bigint      NOT NULL
);

CREATE INDEX src_return_sales_date ON ch11_r.src_return (sales_date);
