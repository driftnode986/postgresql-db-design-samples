-- 元データ（ch02_r.src）を id の順に写す。先に r_source/ の 2 つのファイルを実行しておく
-- 元データが空のまま写すと、空のテーブルで測ることになる。何も消す前に止める
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM ch02_r.src) THEN
    RAISE EXCEPTION '元データ ch02_r.src が空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on
DROP STATISTICS IF EXISTS ch02_b.products_color_size_expr;
DROP INDEX IF EXISTS ch02_b.products_created, ch02_b.products_attrs_path;
TRUNCATE ch02_b.products RESTART IDENTITY;

-- 共通の 5 列を除いた残りを jsonb にまとめ、NULL のキーを取り除く
INSERT INTO ch02_b.products (id, kind, name, price, created_at, attrs)
OVERRIDING SYSTEM VALUE
SELECT id, kind, name, price, created_at,
       jsonb_strip_nulls(to_jsonb(s) - ARRAY['id', 'kind', 'name', 'price', 'created_at'])
FROM ch02_r.src AS s ORDER BY id;
SELECT setval(pg_get_serial_sequence('ch02_b.products', 'id'),
              (SELECT max(id) FROM ch02_b.products));

CREATE INDEX products_created ON ch02_b.products (created_at DESC);
-- jsonb_path_ops は @>（含む）の検索に向いた GIN インデックスの種類
CREATE INDEX products_attrs_path
  ON ch02_b.products USING gin (attrs jsonb_path_ops);
VACUUM (ANALYZE) ch02_b.products;
