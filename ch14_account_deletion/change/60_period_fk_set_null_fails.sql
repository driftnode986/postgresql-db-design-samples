-- run-as: book_owner
-- expect-error: unsupported ON DELETE action for foreign key constraint using PERIOD
-- standalone
--
-- 同じ期間つき外部キーに ON DELETE SET NULL を付ける。CASCADE と同じエラー文で拒否される。
CREATE SCHEMA IF NOT EXISTS ch14_z;
DROP TABLE IF EXISTS ch14_z.pc_setnull, ch14_z.pp;
CREATE TABLE ch14_z.pp (
  id int, valid daterange,
  PRIMARY KEY (id, valid WITHOUT OVERLAPS)
);
CREATE TABLE ch14_z.pc_setnull (
  id int, p_id int, valid daterange,
  PRIMARY KEY (id, valid WITHOUT OVERLAPS),
  FOREIGN KEY (p_id, PERIOD valid) REFERENCES ch14_z.pp (id, PERIOD valid)
    ON DELETE SET NULL
);
