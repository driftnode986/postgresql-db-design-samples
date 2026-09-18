-- 3 案に同じ商品を入れるための元データ。
-- 元データを 1 回だけ作り、各案の load.sql が ORDER BY id で写す。
-- 案ごとに別々に生成すると、乱数が違って案の比較にならない。
CREATE SCHEMA IF NOT EXISTS ch05_r;

DROP TABLE IF EXISTS ch05_r.src_product;

CREATE TABLE ch05_r.src_product (
  id         bigint PRIMARY KEY,
  sku        text    NOT NULL,
  name       text    NOT NULL,
  price_yen  integer NOT NULL,
  -- 初期の在庫数。1 商品あたり 100 個から始める
  qty        integer NOT NULL
);
