-- 案D: PostgreSQL 18 の PRIMARY KEY (..., period WITHOUT OVERLAPS)
--
-- 案B・案C と守る約束は同じだが、制約の種類が主キーになる。
-- インデックスは一意な GiST インデックスとして作られる（pg_indexes で確認できる）。
--
-- 案C との違いは 2 つ。どちらも実機で確かめたもの。
--   1. WHERE を付けられない（構文エラーになる）。キャンセル済みを判定から外せないので、
--      キャンセルは別の表に移すか、行を消すかで表す
--   2. 空の範囲を自分で拒否する。EXCLUDE は空の範囲を 2 件とも通すので、
--      案C では CHECK (NOT isempty(period)) を自分で書く必要がある
--
-- また、第8章で使う期間つき外部キー（PERIOD）の参照先になれるのはこちらである。
CREATE SCHEMA ch06_c;

CREATE TABLE ch06_c.rooms (
  id   bigint PRIMARY KEY,
  name text   NOT NULL
);

-- キャンセル済みを判定から外せないので、有効な予約だけをこの表に置く。
-- キャンセルは行を消して cancelled_reservations に移す（load.sql と cancel.sql を参照）
CREATE TABLE ch06_c.reservations (
  room_id  bigint      NOT NULL REFERENCES ch06_c.rooms(id),
  period   tstzrange   NOT NULL,
  user_id  bigint      NOT NULL,
  -- 予約を識別する番号。主キーが (room_id, period) なので、こちらは別に持つ
  reservation_no bigint GENERATED ALWAYS AS IDENTITY UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),

  -- 同じ部屋で期間が重なる行を 2 件入れさせない。
  -- 空の範囲は PostgreSQL がここで拒否する（CHECK を自分で書かなくてよい）
  PRIMARY KEY (room_id, period WITHOUT OVERLAPS)
);

-- キャンセル済みの予約。重なり判定に加わらないよう、本体から出してある
CREATE TABLE ch06_c.cancelled_reservations (
  reservation_no bigint      PRIMARY KEY,
  room_id        bigint      NOT NULL,
  period         tstzrange   NOT NULL,
  user_id        bigint      NOT NULL,
  cancelled_at   timestamptz NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE
  ON ch06_c.rooms, ch06_c.reservations, ch06_c.cancelled_reservations TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch06_c TO book_app;
