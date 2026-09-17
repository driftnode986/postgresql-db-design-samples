-- run-as: book_owner
-- expect-error: 0A000
-- 採取した案の 1 つは、子テーブルの CHECK で親の種類を問い合わせていた。
-- PostgreSQL の CHECK には副問い合わせを書けないので、テーブルを作る時点でエラーになる
CREATE TABLE ch02_c.clothing (
  product_id bigint PRIMARY KEY REFERENCES ch02_c.products (id) ON DELETE CASCADE,
  color varchar(100) NOT NULL,
  size  varchar(50)  NOT NULL,
  CONSTRAINT clothing_product_category CHECK (
    (SELECT kind FROM ch02_c.products WHERE id = product_id) = 'apparel'
  )
);
