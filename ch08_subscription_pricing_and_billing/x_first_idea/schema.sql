-- 採取した案（3 本のうち 2 本）が書いた料金表。本書はこの形を採用しない。
--
-- UNIQUE (plan_id, valid_from) は「同じプランの同じ開始日は 1 つだけ」しか言っていない。
-- 開始日が違えば、期間の重なる料金を 2 行入れられる。
--
-- 🔴 この案は、わざと重なる行を入れて何が起きるかを見るために置いてある。
--    そのため EXCLUDE も WITHOUT OVERLAPS も付けない。
CREATE SCHEMA ch08_x;

CREATE TABLE ch08_x.plan_prices (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  plan_id    bigint NOT NULL,
  valid_from date   NOT NULL,
  valid_to   date,
  price_yen  int    NOT NULL CHECK (price_yen > 0),
  UNIQUE (plan_id, valid_from)
);
