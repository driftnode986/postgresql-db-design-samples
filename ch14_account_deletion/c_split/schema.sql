-- 案C: 個人情報を別のテーブルに分ける。退会したらその行だけを消す。
--
-- 🔴 採取した 3 本のうち 2 本（既定・opus）がこの形を推した。
--    既定は前提の 1 行目に「論理削除フラグ 1 本で済ませる設計は取りません。
--    個人情報を『消す』要件があるので、フラグでは消えません」と書いている。
CREATE SCHEMA IF NOT EXISTS ch14_c;

-- 本体。個人情報を一切持たない。注文とコメントはこの id を指す。
CREATE TABLE ch14_c.accounts (
  id           bigint      PRIMARY KEY,
  status       text        NOT NULL DEFAULT 'active'
               CHECK (status IN ('active', 'withdrawn')),
  registered   timestamptz NOT NULL,
  withdrawn_at timestamptz,
  -- 退会していないのに退会日時がある、という矛盾を止める
  CONSTRAINT accounts_withdrawn_consistent CHECK (
    (status = 'active'    AND withdrawn_at IS NULL) OR
    (status = 'withdrawn' AND withdrawn_at IS NOT NULL)
  )
);
CREATE INDEX c_accounts_active ON ch14_c.accounts (registered DESC) WHERE status = 'active';
-- 30日を過ぎた退会アカウントを探すため
CREATE INDEX c_accounts_withdrawn ON ch14_c.accounts (withdrawn_at) WHERE status = 'withdrawn';

-- 個人情報。退会したら行ごと消す。消す対象はこの 1 テーブルに集まっている。
CREATE TABLE ch14_c.profiles (
  account_id bigint PRIMARY KEY REFERENCES ch14_c.accounts(id) ON DELETE CASCADE,
  email      text   NOT NULL,
  full_name  text   NOT NULL,
  postal     text   NOT NULL,
  address    text   NOT NULL,
  phone      text   NOT NULL
);
-- 行ごと消えるので、通常の一意で「退会後に同じメールで再登録」が通る。
CREATE UNIQUE INDEX c_profiles_email ON ch14_c.profiles (email);

-- 注文。個人情報を持たない。売上集計はこのテーブルだけで完結する。
CREATE TABLE ch14_c.orders (
  id         bigint        PRIMARY KEY,
  account_id bigint        NOT NULL REFERENCES ch14_c.accounts(id),
  ordered_at timestamptz   NOT NULL,
  amount     numeric(12,0) NOT NULL CHECK (amount >= 0)
);
CREATE INDEX c_orders_account ON ch14_c.orders (account_id);
CREATE INDEX c_orders_at      ON ch14_c.orders (ordered_at);

-- 🔴 配送先は注文時点の個人情報。注文本体から切り離し、退会時に消せるようにする。
--    案A・案B では orders の列なので、消すと注文の行に触ることになる。
CREATE TABLE ch14_c.order_shipments (
  order_id   bigint PRIMARY KEY REFERENCES ch14_c.orders(id) ON DELETE CASCADE,
  recipient  text   NOT NULL,
  ship_addr  text   NOT NULL,
  ship_phone text   NOT NULL
);

CREATE TABLE ch14_c.comments (
  id         bigint      PRIMARY KEY,
  account_id bigint      NOT NULL REFERENCES ch14_c.accounts(id),
  body       text        NOT NULL,
  posted_at  timestamptz NOT NULL
);
CREATE INDEX c_comments_account ON ch14_c.comments (account_id);
