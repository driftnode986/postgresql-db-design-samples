-- 案B: 条件つき UPDATE を 1 文だけ実行する
--
-- テーブルの形は案A と同じ。違うのは引当の書き方だけで、在庫を読まずに
-- 「足りるときだけ減らす」を 1 文で書く。更新できた行数で成否を判定する。
CREATE SCHEMA ch05_b;

CREATE TABLE ch05_b.products (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku        text        NOT NULL UNIQUE,
  name       text        NOT NULL,
  price_yen  integer     NOT NULL CHECK (price_yen >= 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ch05_b.inventory (
  product_id bigint      PRIMARY KEY REFERENCES ch05_b.products(id),
  qty        integer     NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  -- 案A と同じ二重の備え。WHERE qty >= n が先に効くので、通常はこの制約に到達しない
  CONSTRAINT inventory_qty_non_negative CHECK (qty >= 0)
);

CREATE TABLE ch05_b.orders (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  status     text        NOT NULL DEFAULT 'pending'
             CHECK (status IN ('pending', 'confirmed')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ch05_b.order_items (
  order_id   bigint  NOT NULL REFERENCES ch05_b.orders(id) ON DELETE CASCADE,
  product_id bigint  NOT NULL REFERENCES ch05_b.products(id),
  qty        integer NOT NULL CHECK (qty > 0),
  PRIMARY KEY (order_id, product_id)
);
