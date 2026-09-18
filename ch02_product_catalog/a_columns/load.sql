-- 元データ（ch02_r.src）を id の順に写す。先に r_source/ の 2 つのファイルを実行しておく
-- 元データが空のまま写すと、空のテーブルで測ることになる。何も消す前に止める
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM ch02_r.src) THEN
    RAISE EXCEPTION '元データ ch02_r.src が空。先に r_source/schema_20_generate.sql を実行';
  END IF;
END $$;

\timing on
DROP STATISTICS IF EXISTS ch02_a.products_color_size;
DROP INDEX IF EXISTS ch02_a.products_created,
                     ch02_a.products_color_size_created;
TRUNCATE ch02_a.products RESTART IDENTITY;

-- 列の並びが元データと同じなので、SELECT * で写せる。
-- id を指定して入れるので OVERRIDING SYSTEM VALUE が要る
INSERT INTO ch02_a.products OVERRIDING SYSTEM VALUE
SELECT * FROM ch02_r.src ORDER BY id;
-- id を指定して入れても、シーケンスは進まない。最大の id に合わせる
SELECT setval(pg_get_serial_sequence('ch02_a.products', 'id'),
              (SELECT max(id) FROM ch02_a.products));

-- インデックスは、データを入れた後に作る
CREATE INDEX products_created ON ch02_a.products (created_at DESC);
CREATE INDEX products_color_size_created
  ON ch02_a.products (color, size, created_at DESC);
VACUUM (ANALYZE) ch02_a.products;
