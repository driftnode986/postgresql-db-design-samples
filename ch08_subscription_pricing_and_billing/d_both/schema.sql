-- 案D: 案B（明細に写す）と案C（版つき + 期間つき外部キー）の併用。
--
-- 写しと版は、役割が違う。
--   写し … 発行済みの請求書を、そのままの金額で再現する
--   版   … 「なぜこの金額になったのか」を、料金表までさかのぼって説明する
--
-- 写しだけだと、明細の単価が正しかったのかを照合できない（写した値が唯一の記録になる）。
-- 版だけだと、実際に請求した額が記録に無い（計算し直した額しか出せない）。
--
-- 監査で「この請求の根拠を出せ」と言われる事業は、両方が要る。
CREATE SCHEMA ch08_d;

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;

CREATE TABLE ch08_d.plans (
  id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code text   NOT NULL UNIQUE,
  name text   NOT NULL
);

CREATE TABLE ch08_d.plan_prices (
  plan_id   bigint    NOT NULL REFERENCES ch08_d.plans (id),
  valid     daterange NOT NULL,
  price_yen int       NOT NULL CHECK (price_yen > 0),
  PRIMARY KEY (plan_id, valid WITHOUT OVERLAPS)
);

CREATE TABLE ch08_d.subscriptions (
  id          bigint    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id bigint    NOT NULL,
  plan_id     bigint    NOT NULL,
  period      daterange NOT NULL,
  grandfathered_yen int,
  -- 案C と同じ理由で DEFERRABLE。料金の改定が 2 文になるため（c_temporal/schema.sql の注を参照）
  FOREIGN KEY (plan_id, PERIOD period)
    REFERENCES ch08_d.plan_prices (plan_id, PERIOD valid)
    DEFERRABLE INITIALLY IMMEDIATE
);

CREATE INDEX subscriptions_period ON ch08_d.subscriptions USING gist (period);

-- 明細は写しを持ち、加えて「どの版から引いたか」を持つ。
-- priced_on は、料金表のどの時点の行を使ったかを指す日付である
-- （版の主キーは (plan_id, valid) なので、plan_id と日付があれば 1 行に定まる）。
CREATE TABLE ch08_d.invoice_lines (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  subscription_id bigint NOT NULL REFERENCES ch08_d.subscriptions (id),
  billed_month    date   NOT NULL,
  plan_id         bigint NOT NULL,
  plan_name       text   NOT NULL,
  unit_yen        int    NOT NULL,
  priced_on       date   NOT NULL,          -- この日の版から単価を引いた
  charged_days    int    NOT NULL CHECK (charged_days > 0),
  days_in_month   int    NOT NULL CHECK (days_in_month > 0),
  subtotal_yen    int    GENERATED ALWAYS AS (
                    CASE WHEN charged_days = days_in_month THEN unit_yen
                         ELSE unit_yen * charged_days / days_in_month END
                  ) STORED
);

CREATE INDEX invoice_lines_month ON ch08_d.invoice_lines (billed_month, subscription_id);
