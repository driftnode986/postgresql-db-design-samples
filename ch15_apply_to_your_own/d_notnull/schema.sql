-- 18 で手数が減った変更: NULL が残っている列に、あとから NOT NULL を足す。
CREATE SCHEMA ch15_d;

CREATE TABLE ch15_d.users (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email text
);
