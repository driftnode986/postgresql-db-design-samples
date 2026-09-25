-- 案A: 論理削除。個人情報を利用者の行に置いたまま、deleted_at で印を付ける。
--
-- 採取した案（haiku）がこの形だった。ただし採取した DDL は
--   CONSTRAINT email_unique_when_active UNIQUE (email) WHERE (deleted_at IS NULL)
-- と書いており、これは構文エラーで作れない（x_firstidea/10_haiku_ddl_fails.sql で確かめる）。
-- 部分的な一意は制約では書けず、部分一意インデックスでしか作れないので、そう直してある。
CREATE SCHEMA IF NOT EXISTS ch14_a;

CREATE TABLE ch14_a.users (
  id         bigint      PRIMARY KEY,
  email      text        NOT NULL,
  full_name  text        NOT NULL,
  postal     text        NOT NULL,
  address    text        NOT NULL,
  phone      text        NOT NULL,
  registered timestamptz NOT NULL,
  deleted_at timestamptz
);

-- 退会していない利用者の中でだけメールを一意にする。
-- これで「退会後に同じメールで再登録」が通る（r_source の withdrawn を deleted_at に写す）。
CREATE UNIQUE INDEX users_email_active ON ch14_a.users (email) WHERE deleted_at IS NULL;

-- 一覧は「退会していない利用者を登録の新しい順」。部分インデックスで引く。
CREATE INDEX users_active_registered ON ch14_a.users (registered DESC) WHERE deleted_at IS NULL;

CREATE TABLE ch14_a.orders (
  id         bigint        PRIMARY KEY,
  user_id    bigint        NOT NULL REFERENCES ch14_a.users(id),
  ordered_at timestamptz   NOT NULL,
  amount     numeric(12,0) NOT NULL CHECK (amount >= 0),
  -- 🔴 配送先は注文時点の値。ここにも個人情報が写っている。
  recipient  text          NOT NULL,
  ship_addr  text          NOT NULL,
  ship_phone text          NOT NULL
);
CREATE INDEX orders_user ON ch14_a.orders (user_id);
CREATE INDEX orders_at   ON ch14_a.orders (ordered_at);

CREATE TABLE ch14_a.comments (
  id        bigint      PRIMARY KEY,
  user_id   bigint      NOT NULL REFERENCES ch14_a.users(id),
  body      text        NOT NULL,
  posted_at timestamptz NOT NULL
);
CREATE INDEX comments_user ON ch14_a.comments (user_id);
