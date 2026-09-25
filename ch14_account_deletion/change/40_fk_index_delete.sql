-- run-as: book_owner
-- standalone
--
-- 子の外部キー列に索引が無いと、親 1 行の削除で子を全件走査する。
-- 🔴 案B・案C は退会で親の行を消すので、この差が退会の速さに直接効く。
--
-- 索引の有無だけを変えるため、親も子も 2 組つくって分ける
-- （1 つの親に両方の子をぶら下げると連鎖が同時に走り、分けて測れない）。
CREATE SCHEMA IF NOT EXISTS ch14_z;
DROP TABLE IF EXISTS ch14_z.c_noidx, ch14_z.c_idx, ch14_z.pa_n, ch14_z.pa_i;

CREATE TABLE ch14_z.pa_n (id bigint PRIMARY KEY);
CREATE TABLE ch14_z.pa_i (id bigint PRIMARY KEY);
INSERT INTO ch14_z.pa_n SELECT generate_series(1, 1000);
INSERT INTO ch14_z.pa_i SELECT generate_series(1, 1000);

CREATE TABLE ch14_z.c_noidx (
  id bigint PRIMARY KEY, p bigint REFERENCES ch14_z.pa_n(id) ON DELETE CASCADE);
CREATE TABLE ch14_z.c_idx (
  id bigint PRIMARY KEY, p bigint REFERENCES ch14_z.pa_i(id) ON DELETE CASCADE);

INSERT INTO ch14_z.c_noidx SELECT i, 1 + (i % 1000) FROM generate_series(1, 500000) i;
INSERT INTO ch14_z.c_idx   SELECT i, 1 + (i % 1000) FROM generate_series(1, 500000) i;
CREATE INDEX c_idx_p ON ch14_z.c_idx (p);
VACUUM ANALYZE ch14_z.pa_n, ch14_z.pa_i, ch14_z.c_noidx, ch14_z.c_idx;

-- 3 回ずつ交互に測る（キャッシュの状態をそろえるため）
\timing on
DELETE FROM ch14_z.pa_n WHERE id = 5;   -- 索引なし 1 回目
DELETE FROM ch14_z.pa_i WHERE id = 5;   -- 索引あり 1 回目
DELETE FROM ch14_z.pa_n WHERE id = 6;   -- 索引なし 2 回目
DELETE FROM ch14_z.pa_i WHERE id = 6;   -- 索引あり 2 回目
DELETE FROM ch14_z.pa_n WHERE id = 7;   -- 索引なし 3 回目
DELETE FROM ch14_z.pa_i WHERE id = 7;   -- 索引あり 3 回目
\timing off
