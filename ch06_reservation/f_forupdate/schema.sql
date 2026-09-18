-- 検算の対象: 重なる予約を SELECT ... FOR UPDATE でロックしてから INSERT する
--
-- 🔴 これは「最初に思いつく案」の採取で実際に出てきた案（docs/research/ch06_first_idea.md の haiku）。
--    著者が作った藁人形ではない。重なり判定の不等式そのものは正しい:
--      start_at < 申込の終了 AND end_at > 申込の開始
--    10:00-11:00 と 11:00-12:00 なら 11:00 > 11:00 が偽になり、重ならないと判定される。
--
-- 問題は FOR UPDATE のほうにある。FOR UPDATE は「返ってきた行」にロックを掛ける道具で、
-- まだ存在しない行は掛けようがない。重なる予約が 0 件の枠では 0 行が返るので、
-- ロックは 1 つも取られない。2 つの接続が同時に「0 件」と読んで、2 件とも INSERT できる。
--
-- 第5章の在庫では同じ FOR UPDATE が効いた。在庫は行が先にあるからである。
-- 同じ道具が、行が先にあるかどうかで効いたり効かなかったりする。
CREATE SCHEMA ch06_f;

CREATE TABLE ch06_f.rooms (
  id   bigint PRIMARY KEY,
  name text   NOT NULL
);

CREATE TABLE ch06_f.reservations (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id      bigint      NOT NULL REFERENCES ch06_f.rooms(id),
  user_id      bigint      NOT NULL,
  start_at     timestamptz NOT NULL,
  end_at       timestamptz NOT NULL,
  cancelled_at timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT reservations_time_order CHECK (start_at < end_at)
);

-- 採取した案が付けていた部分インデックス。有効な予約だけを引く
CREATE INDEX reservations_active_idx
  ON ch06_f.reservations (room_id, start_at, end_at)
  WHERE cancelled_at IS NULL;
