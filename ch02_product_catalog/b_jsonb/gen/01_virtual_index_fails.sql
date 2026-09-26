-- run-as: book_owner
-- expect-error: indexes on virtual generated columns are not supported
-- 17 以前の記事の書き方から STORED を省いて写した場合。18 では、書かなければ VIRTUAL の生成列になる。
-- エラーで止まるとトランザクションごと取り消されるので、足した列は残らない
BEGIN;
ALTER TABLE ch02_b.products
  ADD COLUMN color text GENERATED ALWAYS AS (attrs->>'color');
-- attgenerated が v なら仮想（VIRTUAL）、s なら保存（STORED）
SELECT attname, attgenerated FROM pg_attribute
WHERE attrelid = 'ch02_b.products'::regclass AND attname = 'color';
CREATE INDEX products_color ON ch02_b.products (color);
ROLLBACK;
