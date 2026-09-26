-- 案B: 期間を範囲型の 1 列で持ち、排他制約で守る
--
-- 採取した案（opus）がこの形だった。案A と守る約束は同じで、列の持ち方だけが違う。
-- 範囲型にすると、重なり（&&）・包含（@>）・隣接（-|-）が演算子で書ける。
-- 一方で、開始時刻だけを取り出すには lower(period) と書くことになる。
CREATE SCHEMA ch06_b;

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE ch06_b.rooms (
  id   bigint PRIMARY KEY,
  name text   NOT NULL
);

CREATE TABLE ch06_b.reservations (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id      bigint      NOT NULL REFERENCES ch06_b.rooms(id),
  user_id      bigint      NOT NULL,
  -- 期間を 1 列で持つ。'[)' で作るので、終了時刻は含まれない
  period       tstzrange   NOT NULL,
  cancelled_at timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  -- 空の範囲を入れさせない。空の範囲は何とも重ならないので、制約をすり抜ける
  CONSTRAINT reservations_period_not_empty CHECK (NOT isempty(period)),

  CONSTRAINT reservations_no_overlap EXCLUDE USING gist (
    room_id WITH =,
    period  WITH &&
  ) WHERE (cancelled_at IS NULL)
);

GRANT SELECT, INSERT, UPDATE ON ch06_b.rooms, ch06_b.reservations TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch06_b TO book_app;
