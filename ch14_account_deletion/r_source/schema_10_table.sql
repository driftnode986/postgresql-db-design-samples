-- 第14章の元データ。3 案（案A・案B・案C）はここから同じ中身を写す。
--
-- 🔴 案ごとにデータを作り直すと、案の違いではなく乱数の違いを測ることになる。
--    元データを 1 回だけ作り、各案の load.sql が ORDER BY id で写す。
--
-- 元データが持つのは「利用者」「注文」「コメント」の 3 つだけである。
-- 個人情報を利用者の行に置くか（案A・案B）、別のテーブルに分けるか（案C）は各案が決める。
CREATE SCHEMA IF NOT EXISTS ch14_r;

DROP TABLE IF EXISTS ch14_r.src_comment;
DROP TABLE IF EXISTS ch14_r.src_order;
DROP TABLE IF EXISTS ch14_r.src_user;

-- 利用者。withdrawn が真の行は「すでに退会している」利用者を表す。
-- 退会済みの割合を変えて測るため、元データの時点で印を持たせる。
CREATE TABLE ch14_r.src_user (
  id         bigint      PRIMARY KEY,
  email      text        NOT NULL,
  full_name  text        NOT NULL,
  postal     text        NOT NULL,
  address    text        NOT NULL,
  phone      text        NOT NULL,
  registered timestamptz NOT NULL,
  withdrawn  boolean     NOT NULL
);

-- 注文。売上集計は退会の前後で変わってはいけないので、金額と日時だけを持つ。
-- 宛名と住所は注文時点の値で、これは個人情報である（配送先として残りがちな場所）。
CREATE TABLE ch14_r.src_order (
  id         bigint        PRIMARY KEY,
  user_id    bigint        NOT NULL REFERENCES ch14_r.src_user(id),
  ordered_at timestamptz   NOT NULL,
  amount     numeric(12,0) NOT NULL CHECK (amount >= 0),
  recipient  text          NOT NULL,
  ship_addr  text          NOT NULL,
  ship_phone text          NOT NULL
);

-- 掲示板のコメント。退会後も本文は残り、表示名だけが「退会した利用者」になる。
CREATE TABLE ch14_r.src_comment (
  id        bigint      PRIMARY KEY,
  user_id   bigint      NOT NULL REFERENCES ch14_r.src_user(id),
  body      text        NOT NULL,
  posted_at timestamptz NOT NULL
);
