-- run-as: book_owner
-- standalone
--
-- 変更シナリオ: 案A の users と orders から、個人情報を別のテーブルに切り出す（案A → 案C）。
-- 変更の手数を 4 点で記録する: SQL 文の数・テーブルの書き換えの有無・取るロック・所要時間。
--
-- 🔴 全体を BEGIN … ROLLBACK で囲む。消した列の定義はテーブルに残るので、
--    確定させるとほかの測定のサイズが変わる（第1章の規約）。
\timing on

SELECT pg_relation_filenode('ch14_a.users')  AS users_filenode_before,
       pg_relation_filenode('ch14_a.orders') AS orders_filenode_before;

BEGIN;

-- (1) 利用者の個人情報を切り出す（文 1〜4）
CREATE TABLE ch14_a.profiles (
    user_id   bigint PRIMARY KEY REFERENCES ch14_a.users (id) ON DELETE CASCADE,
    email     text NOT NULL,
    full_name text NOT NULL,
    postal    text NOT NULL,
    address   text NOT NULL,
    phone     text NOT NULL
);
INSERT INTO ch14_a.profiles
SELECT id, email, full_name, postal, address, phone
FROM ch14_a.users WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX a_profiles_email ON ch14_a.profiles (email);
ALTER TABLE ch14_a.users
  DROP COLUMN email, DROP COLUMN full_name, DROP COLUMN postal,
  DROP COLUMN address, DROP COLUMN phone;

-- (2) 注文の配送先を切り出す（文 5〜7）
CREATE TABLE ch14_a.order_shipments (
    order_id   bigint PRIMARY KEY REFERENCES ch14_a.orders (id) ON DELETE CASCADE,
    recipient  text NOT NULL,
    ship_addr  text NOT NULL,
    ship_phone text NOT NULL
);
INSERT INTO ch14_a.order_shipments
SELECT id, recipient, ship_addr, ship_phone FROM ch14_a.orders;
ALTER TABLE ch14_a.orders
  DROP COLUMN recipient, DROP COLUMN ship_addr, DROP COLUMN ship_phone;

-- このトランザクションが users と orders に持っているロック
SELECT c.relname AS locked_table, l.mode AS lock_mode
FROM pg_locks l JOIN pg_class c ON c.oid = l.relation
WHERE l.pid = pg_backend_pid() AND c.relname IN ('users', 'orders')
  AND c.relnamespace = 'ch14_a'::regnamespace
ORDER BY 1, 2;

SELECT pg_relation_filenode('ch14_a.users')  AS users_filenode_after,
       pg_relation_filenode('ch14_a.orders') AS orders_filenode_after;

ROLLBACK;
\timing off
