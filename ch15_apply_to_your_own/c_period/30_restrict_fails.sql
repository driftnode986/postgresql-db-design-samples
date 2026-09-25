-- run-as: book_owner
-- expect-error: unsupported ON DELETE action for foreign key constraint using PERIOD
-- 参照先を消せないようにする RESTRICT も、期間つき外部キーには付けられない。
CREATE TABLE ch15_c.contracts_restrict (
  id      bigint PRIMARY KEY,
  plan_id bigint NOT NULL,
  valid   daterange NOT NULL,
  FOREIGN KEY (plan_id, PERIOD valid)
    REFERENCES ch15_c.plan_prices (plan_id, PERIOD valid)
    ON DELETE RESTRICT
);
