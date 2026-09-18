-- 4 案に同じ契約・同じ料金改定を入れるための元データ。
-- 元データを 1 回だけ作り、各案の load.sql が ORDER BY id で写す。
-- 案ごとに別々に生成すると、乱数が違って案の比較にならない。
CREATE SCHEMA IF NOT EXISTS ch08_r;

DROP TABLE IF EXISTS ch08_r.src_sub_period;
DROP TABLE IF EXISTS ch08_r.src_subscription;
DROP TABLE IF EXISTS ch08_r.src_price;
DROP TABLE IF EXISTS ch08_r.src_plan;

-- プラン。料金そのものは持たない（料金は改定されるので src_price 側の期間つきの行が持つ）
CREATE TABLE ch08_r.src_plan (
  id   bigint PRIMARY KEY,
  code text   NOT NULL,
  name text   NOT NULL
);

-- 料金の版。1 つのプランに、期間を区切って複数行。
-- valid は半開区間 [開始, 終了) で、同じプランの行どうしは重ならない。
--
-- 🔴 「重ならない」ことと「切れ目なく続く」ことは別である。
--    この元データは切れ目なく作るが、第8章の本文ではわざとすき間のある料金表も作る。
CREATE TABLE ch08_r.src_price (
  id       bigint    PRIMARY KEY,
  plan_id  bigint    NOT NULL REFERENCES ch08_r.src_plan (id),
  valid    daterange NOT NULL,
  price_yen int      NOT NULL CHECK (price_yen > 0)
);

-- 契約。1 つの契約が、期間を区切って複数のプランを持つ（プラン変更）。
CREATE TABLE ch08_r.src_subscription (
  id          bigint PRIMARY KEY,
  customer_id bigint NOT NULL,
  started_on  date   NOT NULL
);

-- 契約 × プランの期間。プラン変更は「前の行を閉じて新しい行を足す」で表す。
--
-- 🔴 grandfathered_yen が入っている行は、料金表を引かずにこの額で請求する（据え置き）。
--    据え置きの表し方は採取した 3 本で 3 通りに割れた（ch08_first_idea.md）。
--    ここでは元データとして「金額そのもの」を持ち、各案が自分の形に写す。
CREATE TABLE ch08_r.src_sub_period (
  id              bigint    PRIMARY KEY,
  subscription_id bigint    NOT NULL REFERENCES ch08_r.src_subscription (id),
  plan_id         bigint    NOT NULL REFERENCES ch08_r.src_plan (id),
  period          daterange NOT NULL,
  grandfathered_yen int
);
