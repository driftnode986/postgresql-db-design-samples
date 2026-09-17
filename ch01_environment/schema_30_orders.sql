-- データ量と 4 つの指標の説明に使う、注文明細のテーブル
CREATE TABLE ch01.order_items (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id  int         NOT NULL,
  qty         int         NOT NULL,
  ordered_at  timestamptz NOT NULL
);
