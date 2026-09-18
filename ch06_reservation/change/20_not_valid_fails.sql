-- run-as: book_owner
-- expect-error: EXCLUDE constraints cannot be marked NOT VALID
--
-- 排他制約は NOT VALID で足せない。
-- 外部キーや CHECK には「先に制約を足して、既にある行の検証はあとで行う」ための
-- NOT VALID があり、これを使うと表を長時間止めずに制約を足せる。
-- 排他制約にはこの逃げ道が無いので、移行のあいだ表が止まる。
ALTER TABLE ch06_b.reservations
  ADD CONSTRAINT reservations_nv EXCLUDE USING gist (
    room_id WITH =, tstzrange(start_at, end_at, '[)') WITH &&) NOT VALID;
