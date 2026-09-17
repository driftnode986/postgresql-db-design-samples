-- 第1章の最初の節で使う、予約の 2 つの方式。
-- どちらも「同じ部屋の同じ時間に 2 件入れない」を目的にしている。
-- データベースとの往復の回数をそろえるため、どちらも 1 回の関数呼び出しにまとめる。
CREATE SCHEMA ch01;

-- 方式1: 空いていることを SELECT で確かめてから INSERT する（制約なし）
CREATE TABLE ch01.resv_check (
  id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id  int       NOT NULL,
  period   tstzrange NOT NULL
);
CREATE INDEX ON ch01.resv_check USING gist (room_id, period);

CREATE FUNCTION ch01.book_check(p_room int, p_period tstzrange)
RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM ch01.resv_check
             WHERE room_id = p_room AND period && p_period) THEN
    RETURN false;
  END IF;
  INSERT INTO ch01.resv_check (room_id, period) VALUES (p_room, p_period);
  RETURN true;
END $$;

-- 方式2: 重なる予約をデータベースが拒否する（排他制約）
CREATE TABLE ch01.resv_excl (
  id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id  int       NOT NULL,
  period   tstzrange NOT NULL,
  EXCLUDE USING gist (room_id WITH =, period WITH &&)
);

-- 制約違反は pgbench のクライアントを止めるので、関数の中で受けて false を返す
CREATE FUNCTION ch01.book_excl(p_room int, p_period tstzrange)
RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO ch01.resv_excl (room_id, period) VALUES (p_room, p_period);
  RETURN true;
EXCEPTION WHEN exclusion_violation THEN
  RETURN false;
END $$;
