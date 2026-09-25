-- 案B: 物理削除 + アーカイブ。
-- 退会したら利用者の行を消す。30日以内に戻せるよう、消す直前の個人情報を
-- 復元用のテーブルに写しておく。
--
-- 🔴 この案の弱点は設計そのものに現れる。「個人情報を消す」要件なのに、
--    復元のためにアーカイブへ写すので、消えていない。30日で消す仕組みが要る。
CREATE SCHEMA IF NOT EXISTS ch14_b;

CREATE TABLE ch14_b.users (
  id         bigint      PRIMARY KEY,
  email      text        NOT NULL UNIQUE,   -- 行ごと消えるので通常の一意で足りる
  full_name  text        NOT NULL,
  postal     text        NOT NULL,
  address    text        NOT NULL,
  phone      text        NOT NULL,
  registered timestamptz NOT NULL
);
CREATE INDEX b_users_registered ON ch14_b.users (registered DESC);

-- 退会した利用者の控え。30日を過ぎたらここからも消す。
CREATE TABLE ch14_b.withdrawn_users (
  id           bigint      PRIMARY KEY,
  email        text        NOT NULL,
  full_name    text        NOT NULL,
  postal       text        NOT NULL,
  address      text        NOT NULL,
  phone        text        NOT NULL,
  registered   timestamptz NOT NULL,
  withdrawn_at timestamptz NOT NULL,
  -- 30日を過ぎた控えを探すための索引
  purge_after  timestamptz NOT NULL
);
CREATE INDEX b_withdrawn_purge ON ch14_b.withdrawn_users (purge_after);

-- 🔴 注文は利用者を消しても残さなければならない（売上集計が変わってはいけない）。
--    したがって ON DELETE CASCADE にはできない。SET NULL にして参照だけ切る。
CREATE TABLE ch14_b.orders (
  id         bigint        PRIMARY KEY,
  user_id    bigint        REFERENCES ch14_b.users(id) ON DELETE SET NULL,
  ordered_at timestamptz   NOT NULL,
  amount     numeric(12,0) NOT NULL CHECK (amount >= 0),
  recipient  text          NOT NULL,
  ship_addr  text          NOT NULL,
  ship_phone text          NOT NULL
);
-- 🔴 外部キーの列に索引が無いと、親 1 行の削除で子を全件走査する（ch14_verification.md §5）。
CREATE INDEX b_orders_user ON ch14_b.orders (user_id);
CREATE INDEX b_orders_at   ON ch14_b.orders (ordered_at);

CREATE TABLE ch14_b.comments (
  id        bigint      PRIMARY KEY,
  user_id   bigint      REFERENCES ch14_b.users(id) ON DELETE SET NULL,
  body      text        NOT NULL,
  posted_at timestamptz NOT NULL
);
CREATE INDEX b_comments_user ON ch14_b.comments (user_id);
