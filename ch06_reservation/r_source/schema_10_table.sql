-- 4 案に同じ予約を入れるための元データ。
-- 元データを 1 回だけ作り、各案の load.sql が ORDER BY id で写す。
-- 案ごとに別々に生成すると、乱数が違って案の比較にならない。
CREATE SCHEMA IF NOT EXISTS ch06_r;

DROP TABLE IF EXISTS ch06_r.src_reservation;
DROP TABLE IF EXISTS ch06_r.src_room;

CREATE TABLE ch06_r.src_room (
  id    bigint PRIMARY KEY,
  name  text   NOT NULL
);

-- 既にある予約。開始・終了の 2 列で持つ（範囲型の案も 2 列の案も、ここから写す）。
-- 枠は 1 時間刻みでそろえてあるので、どの案でも同じ重なり方になる。
CREATE TABLE ch06_r.src_reservation (
  id        bigint      PRIMARY KEY,
  room_id   bigint      NOT NULL,
  user_id   bigint      NOT NULL,
  start_at  timestamptz NOT NULL,
  end_at    timestamptz NOT NULL,
  -- キャンセル済みなら時刻が入る。NULL なら有効な予約
  cancelled_at timestamptz
);
