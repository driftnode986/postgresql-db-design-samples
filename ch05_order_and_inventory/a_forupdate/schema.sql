-- 案A: 在庫の行を SELECT ... FOR UPDATE でロックしてから減らす
--
-- 引当の前に在庫数を読むので、「足りない」と分かった時点で理由を組み立てられる。
-- 読んでから書くまでの間に他の接続が割り込めないよう、読む時点でロックを取る。
CREATE SCHEMA ch05_a;

CREATE TABLE ch05_a.products (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku        text        NOT NULL UNIQUE,
  name       text        NOT NULL,
  price_yen  integer     NOT NULL CHECK (price_yen >= 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 在庫を商品と別のテーブルに置く。在庫は更新が集中し、商品名と価格はほとんど変わらない。
-- 同じ行に混ぜると、在庫を 1 個減らすたびに商品の行がロックされる
CREATE TABLE ch05_a.inventory (
  product_id bigint      PRIMARY KEY REFERENCES ch05_a.products(id),
  qty        integer     NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  -- 二重の備え。この案のようにデータベースの中で qty を直接減らす書き方と組めば効く。
  -- 🔴 読んだ値を書き戻す書き方には効かない（qty は負にならず、減り方が足りないだけなので
  --    制約が一度も破られない。f_naive の測定を参照）
  CONSTRAINT inventory_qty_non_negative CHECK (qty >= 0)
);

CREATE TABLE ch05_a.orders (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  status     text        NOT NULL DEFAULT 'pending'
             CHECK (status IN ('pending', 'confirmed')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ch05_a.order_items (
  order_id   bigint  NOT NULL REFERENCES ch05_a.orders(id) ON DELETE CASCADE,
  product_id bigint  NOT NULL REFERENCES ch05_a.products(id),
  qty        integer NOT NULL CHECK (qty > 0),
  -- 1 注文の中に同じ商品が 2 行入らない。入ると引当の回数が合わなくなる
  PRIMARY KEY (order_id, product_id)
);
