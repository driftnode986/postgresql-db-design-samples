-- 変更シナリオ: 案B（在庫の列）から案C（増減の追記）へ移す
--
-- 測るもの: SQL 文の数 / テーブルの書き換えが起きるか / 取るロック / 所要時間。
-- 🔴 ROLLBACK で終わる。測定のための変更で、ほかの測定のサイズを変えないため
--    （PostgreSQL では消した列の定義がテーブルに残る）。
\timing on
-- 変更の前に filenode を控える（変わっていればテーブルが書き換わったということ）
SELECT pg_relation_filenode('ch05_b.inventory') AS fn_before \gset

BEGIN;

-- 移行の前後で照合するための検査を先に用意する（差が 0 でなくなったら経路の漏れ）
CREATE TEMP TABLE migration_check AS
SELECT product_id, qty AS qty_before FROM ch05_b.inventory;

-- 1 文目: 増減を追記するテーブルを作る
CREATE TABLE ch05_b.inventory_entries (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint      NOT NULL REFERENCES ch05_b.products(id),
  delta      integer     NOT NULL CHECK (delta <> 0),
  reason     text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- このトランザクションが取っているロックを見る（テーブル単位）
SELECT c.relname::text AS rel, l.mode
  FROM pg_locks l JOIN pg_class c ON c.oid = l.relation
  JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE l.pid = pg_backend_pid() AND n.nspname = 'ch05_b'
 ORDER BY 1, 2;

-- 2 文目: 現在の在庫を「入荷 1 行」として書き出す
INSERT INTO ch05_b.inventory_entries (product_id, delta, reason)
SELECT product_id, qty, 'migration' FROM ch05_b.inventory
 WHERE qty <> 0 ORDER BY product_id;

-- 3 文目: 移行が正しいか（全行の先頭列が 0 になること）
SELECT count(*) AS mismatch FROM (
  SELECT m.product_id FROM migration_check m
    LEFT JOIN (SELECT product_id, sum(delta) AS s
                 FROM ch05_b.inventory_entries GROUP BY product_id) e
      ON e.product_id = m.product_id
   WHERE coalesce(e.s, 0) <> m.qty_before) AS d;

-- 元のテーブルが書き換わったかどうか（filenode が変わっていなければ書き換えていない）
SELECT count(*) AS inventory_was_rewritten
  FROM (SELECT pg_relation_filenode('ch05_b.inventory') AS fn) AS x
 WHERE fn <> :fn_before;

ROLLBACK;
