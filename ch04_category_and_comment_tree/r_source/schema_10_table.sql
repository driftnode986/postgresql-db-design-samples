-- 第4章の元データ。3 案がここから同じ木を写す（案ごとに作り直さない）。
-- 性質の違う 2 つの木を持つ。
--   src_cat    商品カテゴリ型   深さ 5・分岐が広い・移動がある
--   src_thread コメントスレッド型 深さ 20・追記が中心・移動はほとんど無い
CREATE SCHEMA IF NOT EXISTS ch04_r;

DROP TABLE IF EXISTS ch04_r.src_cat;
DROP TABLE IF EXISTS ch04_r.src_thread;

CREATE TABLE ch04_r.src_cat (
  id         bigint PRIMARY KEY,
  parent_id  bigint,
  name       text NOT NULL,
  depth      int  NOT NULL,
  pos        int  NOT NULL   -- 同じ親の中での並び順
);

CREATE TABLE ch04_r.src_thread (
  id         bigint PRIMARY KEY,
  parent_id  bigint,
  body       text NOT NULL,
  depth      int  NOT NULL,
  pos        int  NOT NULL
);
