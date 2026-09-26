-- 案A: 開始・終了を 2 列のまま持ち、排他制約の中で範囲を組み立てる
--
-- 採取した案（sonnet）がこの形だった。列は start_at / end_at のままなので、
-- 既にある表の構造を変えずに制約だけを足せる。ORM や既存の問い合わせも書き換えずに済む。
--
-- 制約の中の tstzrange(start_at, end_at, '[)') は式なので、GiST のインデックスもこの式に対して作られる。
CREATE SCHEMA ch06_a;

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE ch06_a.rooms (
  id   bigint PRIMARY KEY,
  name text   NOT NULL
);

CREATE TABLE ch06_a.reservations (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id      bigint      NOT NULL REFERENCES ch06_a.rooms(id),
  user_id      bigint      NOT NULL,
  start_at     timestamptz NOT NULL,
  end_at       timestamptz NOT NULL,
  cancelled_at timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT reservations_time_order CHECK (start_at < end_at),

  -- 同じ部屋で、期間が重なる予約を 2 件入れさせない。
  -- '[)' は開始を含み終了を含まないので、10:00-11:00 と 11:00-12:00 は重ならない。
  -- WHERE でキャンセル済みを判定から外す
  CONSTRAINT reservations_no_overlap EXCLUDE USING gist (
    room_id WITH =,
    tstzrange(start_at, end_at, '[)') WITH &&
  ) WHERE (cancelled_at IS NULL)
);

GRANT SELECT, INSERT, UPDATE ON ch06_a.rooms, ch06_a.reservations TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch06_a TO book_app;
