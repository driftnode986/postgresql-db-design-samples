-- run-as: book_owner
-- 生成列の 3 つの書き方。STORED も VIRTUAL も書かないと、どちらになるか
CREATE TABLE ch01.t_gen (
  price           int NOT NULL,
  qty             int NOT NULL,
  amount_default  int GENERATED ALWAYS AS (price * qty),
  amount_virtual  int GENERATED ALWAYS AS (price * qty) VIRTUAL,
  amount_stored   int GENERATED ALWAYS AS (price * qty) STORED
);
-- attgenerated が v なら仮想、s なら保存
SELECT attname, attgenerated
FROM pg_attribute
WHERE attrelid = 'ch01.t_gen'::regclass AND attgenerated <> ''
ORDER BY attnum;
