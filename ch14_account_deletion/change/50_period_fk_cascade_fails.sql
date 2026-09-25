-- run-as: book_owner
-- expect-error: unsupported ON DELETE action for foreign key constraint using PERIOD
-- standalone
--
-- 期間つき外部キー（第8章の WITHOUT OVERLAPS）に、退会の連鎖 ON DELETE CASCADE を付ける。
-- 🔴 18.6 では拒否される。ON DELETE SET NULL も同じエラー文になる（60_ を参照）。
CREATE SCHEMA IF NOT EXISTS ch14_z;
DROP TABLE IF EXISTS ch14_z.pc_cascade, ch14_z.pp;
CREATE TABLE ch14_z.pp (
  id int, valid daterange,
  PRIMARY KEY (id, valid WITHOUT OVERLAPS)
);
CREATE TABLE ch14_z.pc_cascade (
  id int, p_id int, valid daterange,
  PRIMARY KEY (id, valid WITHOUT OVERLAPS),
  FOREIGN KEY (p_id, PERIOD valid) REFERENCES ch14_z.pp (id, PERIOD valid)
    ON DELETE CASCADE
);
