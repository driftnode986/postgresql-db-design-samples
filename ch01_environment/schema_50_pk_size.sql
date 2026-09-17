-- 主キーの型だけが違う、親 1・子 3 のテーブルを 3 組作る。
-- b_ は bigint の IDENTITY、u7_ は uuidv7()、u4_ は uuidv4()
CREATE TABLE ch01.b_orders (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ordered_at timestamptz NOT NULL);
CREATE TABLE ch01.b_items (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES ch01.b_orders, qty int NOT NULL);
CREATE TABLE ch01.b_payments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES ch01.b_orders, amount int NOT NULL);
CREATE TABLE ch01.b_shipments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES ch01.b_orders, shipped_at timestamptz);
CREATE INDEX ON ch01.b_items (order_id);
CREATE INDEX ON ch01.b_payments (order_id);
CREATE INDEX ON ch01.b_shipments (order_id);

CREATE TABLE ch01.u7_orders (
  id uuid DEFAULT uuidv7() PRIMARY KEY,
  ordered_at timestamptz NOT NULL);
CREATE TABLE ch01.u7_items (
  id uuid DEFAULT uuidv7() PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES ch01.u7_orders, qty int NOT NULL);
CREATE TABLE ch01.u7_payments (
  id uuid DEFAULT uuidv7() PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES ch01.u7_orders, amount int NOT NULL);
CREATE TABLE ch01.u7_shipments (
  id uuid DEFAULT uuidv7() PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES ch01.u7_orders, shipped_at timestamptz);
CREATE INDEX ON ch01.u7_items (order_id);
CREATE INDEX ON ch01.u7_payments (order_id);
CREATE INDEX ON ch01.u7_shipments (order_id);

CREATE TABLE ch01.u4_orders (
  id uuid DEFAULT uuidv4() PRIMARY KEY,
  ordered_at timestamptz NOT NULL);
CREATE TABLE ch01.u4_items (
  id uuid DEFAULT uuidv4() PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES ch01.u4_orders, qty int NOT NULL);
CREATE TABLE ch01.u4_payments (
  id uuid DEFAULT uuidv4() PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES ch01.u4_orders, amount int NOT NULL);
CREATE TABLE ch01.u4_shipments (
  id uuid DEFAULT uuidv4() PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES ch01.u4_orders, shipped_at timestamptz);
CREATE INDEX ON ch01.u4_items (order_id);
CREATE INDEX ON ch01.u4_payments (order_id);
CREATE INDEX ON ch01.u4_shipments (order_id);
