-- 衝突3: 料金の版を期間で持ち（第8章）、契約が期間つき外部キーで版を参照する。
CREATE SCHEMA ch15_c;

CREATE TABLE ch15_c.plan_prices (
  plan_id bigint,
  valid   daterange,
  price   integer NOT NULL,
  PRIMARY KEY (plan_id, valid WITHOUT OVERLAPS)
);

CREATE TABLE ch15_c.contracts (
  id      bigint PRIMARY KEY,
  plan_id bigint NOT NULL,
  valid   daterange NOT NULL,
  FOREIGN KEY (plan_id, PERIOD valid)
    REFERENCES ch15_c.plan_prices (plan_id, PERIOD valid)
);
