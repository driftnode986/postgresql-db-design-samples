-- 案C: 在庫の増減を行として追記し、有効在庫を集計で導出する
--
-- 在庫数を持つ列を更新しない。入荷を正、引当を負として 1 行ずつ足していき、
-- 合計が現在の在庫になる。いつ・どの注文で何個減ったかが残る。
CREATE SCHEMA ch05_c;

CREATE TABLE ch05_c.products (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku        text        NOT NULL UNIQUE,
  name       text        NOT NULL,
  price_yen  integer     NOT NULL CHECK (price_yen >= 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 在庫の変動。入荷は正、引当は負
CREATE TABLE ch05_c.inventory_entries (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint      NOT NULL REFERENCES ch05_c.products(id),
  delta      integer     NOT NULL CHECK (delta <> 0),
  reason     text        NOT NULL
             CHECK (reason IN ('receipt', 'allocation', 'release')),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 商品ごとの合計を取るためのインデックス。delta を含めるので、
-- テーブル本体を読まずにインデックスだけで合計できる
CREATE INDEX inventory_entries_product_idx
  ON ch05_c.inventory_entries (product_id) INCLUDE (delta);

CREATE TABLE ch05_c.orders (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  status     text        NOT NULL DEFAULT 'pending'
             CHECK (status IN ('pending', 'confirmed')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ch05_c.order_items (
  order_id   bigint  NOT NULL REFERENCES ch05_c.orders(id) ON DELETE CASCADE,
  product_id bigint  NOT NULL REFERENCES ch05_c.products(id),
  qty        integer NOT NULL CHECK (qty > 0),
  PRIMARY KEY (order_id, product_id)
);

-- 有効在庫。商品ごとの合計
CREATE VIEW ch05_c.available AS
SELECT p.id AS product_id,
       coalesce(sum(e.delta), 0)::int AS qty
  FROM ch05_c.products p
  LEFT JOIN ch05_c.inventory_entries e ON e.product_id = p.id
 GROUP BY p.id;

GRANT SELECT ON ch05_c.available TO book_app;
