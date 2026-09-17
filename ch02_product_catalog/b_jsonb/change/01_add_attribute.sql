-- 変更の手数（案B）: 属性「原産国」を足す → 必須にする → 絞り込めるようにする。
-- 文ごとに取るロックを分けて見るために、手順ごとにトランザクションを確定し、最後に元へ戻す
\timing on

-- 1. 属性を足す。テーブルの定義は変えない（0 文）。新しい商品の attrs にキーを入れるだけ。
--    既存の商品にも値を持たせるなら、全行の UPDATE になる
SELECT pg_size_pretty(pg_total_relation_size('ch02_b.products')) AS total_before;
UPDATE ch02_b.products SET attrs = attrs || '{"origin": "JP"}';
-- 更新前の行の回収と、GIN インデックスの未整理の項目の取り込みを済ませてから測る
VACUUM (ANALYZE) ch02_b.products;
SELECT pg_size_pretty(pg_total_relation_size('ch02_b.products')) AS total_after;

-- 2. 必須にする。「キーがある」と「文字列である」で CHECK が 2 つ要る
BEGIN;
ALTER TABLE ch02_b.products
  ADD CONSTRAINT attrs_has_origin CHECK (attrs ? 'origin') NOT VALID,
  ADD CONSTRAINT origin_is_string
      CHECK (jsonb_typeof(attrs->'origin') = 'string') NOT VALID;
SELECT mode FROM pg_locks
WHERE relation = 'ch02_b.products'::regclass AND pid = pg_backend_pid();
COMMIT;
BEGIN;
ALTER TABLE ch02_b.products VALIDATE CONSTRAINT attrs_has_origin;
ALTER TABLE ch02_b.products VALIDATE CONSTRAINT origin_is_string;
SELECT mode FROM pg_locks
WHERE relation = 'ch02_b.products'::regclass AND pid = pg_backend_pid();
COMMIT;

-- 3. 絞り込めるようにする。@> の検索なら、いまある GIN インデックスがそのまま使われる（0 文）。
--    ただし、全商品が持つキーを条件に入れると、GIN はその全商品ぶんの項目を読む。
--    比べるのは Bitmap Index Scan の時間。先に 1 回実行して、読むページを共有バッファに載せておく
SELECT count(*) FROM products WHERE attrs @> '{"color": "teal"}';
EXPLAIN (ANALYZE)
SELECT id FROM products WHERE attrs @> '{"color": "teal"}';
EXPLAIN (ANALYZE)
SELECT id FROM products WHERE attrs @> '{"origin": "JP", "color": "teal"}';

-- 元に戻す。全行を 2 回更新したのでテーブルが大きくなっている。測定を続けるときは load.sql で入れ直す
ALTER TABLE ch02_b.products
  DROP CONSTRAINT attrs_has_origin, DROP CONSTRAINT origin_is_string;
UPDATE ch02_b.products SET attrs = attrs - 'origin';
