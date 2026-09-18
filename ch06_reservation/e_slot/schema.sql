-- 案E: 時間枠を行として持ち、UNIQUE (room_id, slot_start) で守る
--
-- 範囲型も GiST も使わない。B-tree の一意制約だけで重複を防ぐ。
-- 予約は「枠の集まり」になるので、10:00-12:00 の予約は 2 行（10 時台と 11 時台）になる。
--
-- この案が成り立つのは、枠の長さが決まっている場合に限る。
-- 15 分刻みの申し込みが混ざると、枠の刻みをすべて 15 分にするか、この案をあきらめることになる。
--
-- 利点は 3 つ。拡張が要らない。一意制約なので他のデータベースへ移しやすい。
-- ORM が範囲型を扱えなくても書ける。
CREATE SCHEMA ch06_e;

CREATE TABLE ch06_e.rooms (
  id   bigint PRIMARY KEY,
  name text   NOT NULL
);

-- 予約そのもの（利用者から見た 1 件）
CREATE TABLE ch06_e.reservations (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id      bigint      NOT NULL REFERENCES ch06_e.rooms(id),
  user_id      bigint      NOT NULL,
  cancelled_at timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- 予約が占める枠。1 時間刻み。
-- 重複を防ぐのはこの一意制約で、範囲の重なり判定は登場しない
CREATE TABLE ch06_e.reservation_slots (
  room_id        bigint      NOT NULL,
  slot_start     timestamptz NOT NULL,
  reservation_id bigint      NOT NULL REFERENCES ch06_e.reservations(id) ON DELETE CASCADE,
  -- 枠の刻みからずれた申し込みを入れさせない。
  -- この案が「枠の長さが決まっている場合に限る」ことを、制約として書いておく
  CONSTRAINT slots_on_the_hour
    CHECK (date_trunc('hour', slot_start) = slot_start),
  PRIMARY KEY (room_id, slot_start)
);

CREATE INDEX reservation_slots_reservation_idx
  ON ch06_e.reservation_slots (reservation_id);

GRANT SELECT, INSERT, UPDATE, DELETE
  ON ch06_e.rooms, ch06_e.reservations, ch06_e.reservation_slots TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch06_e TO book_app;
