-- 第5章で使う機能を、最小の例で確かめる。本文で断定する前に、この出力を根拠にする。
--
-- 🔴 版の帰属に注意。merge_action() と MERGE ... RETURNING は 17 で入った。
--    18 で入ったのは RETURNING の old / new の別名のほう。
--    「18 の新機能で入荷処理が 1 文になる」と書くと誤りになる。
-- run-as: book_owner
CREATE SCHEMA IF NOT EXISTS ch05_x;

\echo '## MERGE ... RETURNING merge_action()（PostgreSQL 17。挿入と更新を 1 文で区別する）'
DROP TABLE IF EXISTS ch05_x.inv;
CREATE TABLE ch05_x.inv (product_id bigint PRIMARY KEY, qty int NOT NULL);
INSERT INTO ch05_x.inv VALUES (1, 10);

MERGE INTO ch05_x.inv AS t
USING (VALUES (1::bigint, 5), (2::bigint, 7)) AS s(product_id, delta)
   ON t.product_id = s.product_id
 WHEN MATCHED THEN UPDATE SET qty = t.qty + s.delta
 WHEN NOT MATCHED THEN INSERT (product_id, qty) VALUES (s.product_id, s.delta)
RETURNING merge_action() AS action, t.product_id, t.qty;

\echo '## RETURNING old / new（引当の前後の在庫を 1 文で取る。PostgreSQL 18）'
UPDATE ch05_x.inv SET qty = qty - 3 WHERE product_id = 1
RETURNING old.qty AS before, new.qty AS after;

\echo '## FOR UPDATE SKIP LOCKED（期限切れの仮押さえを、掴まれている行を飛ばして取る）'
DROP TABLE IF EXISTS ch05_x.holds;
CREATE TABLE ch05_x.holds (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL, qty int NOT NULL,
  expires_at timestamptz NOT NULL);
INSERT INTO ch05_x.holds (product_id, qty, expires_at)
SELECT g, 1, now() - interval '20 minutes' FROM generate_series(1, 5) AS g;

SELECT id, product_id FROM ch05_x.holds
 WHERE expires_at < now() ORDER BY id LIMIT 3 FOR UPDATE SKIP LOCKED;
