-- 案B: 全員向けの告知は 1 行だけ持ち、既読を別の表に記録する（fan-out on read）
--
-- 個別の通知は案A と同じく受信者ごとの行にする。
-- 全員向けの告知だけを 1 行にし、「読んだ人」の行だけを別表に作る。
-- 未読は「告知はあるが、読んだ記録が無い」という形で求める。
--
-- 利点: 告知 1 件の配信が 1 行で済む。
-- 代償: 一覧を出すのに 2 つの表を混ぜる必要がある。

CREATE SCHEMA IF NOT EXISTS ch10_b;

DROP TABLE IF EXISTS ch10_b.broadcast_reads;
DROP TABLE IF EXISTS ch10_b.broadcasts;
DROP TABLE IF EXISTS ch10_b.notifications;

-- 個別の通知（案A と同じ形）
CREATE TABLE ch10_b.notifications (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  kind       text        NOT NULL,
  body       text        NOT NULL,
  read_at    timestamptz,
  created_at timestamptz NOT NULL
);

-- 全員向けの告知。1 件につき 1 行しか作らない。
-- 🔴 id は元データの src_notice.id をそのまま使う（IDENTITY にしない）。
--    案どうしで同じ告知が同じ id を持っていないと、検査で突き合わせられない。
CREATE TABLE ch10_b.broadcasts (
  id         bigint      PRIMARY KEY,
  kind       text        NOT NULL,
  body       text        NOT NULL,
  created_at timestamptz NOT NULL
);

-- 告知を読んだ人だけを記録する。読んでいない人の行は作らない
CREATE TABLE ch10_b.broadcast_reads (
  broadcast_id bigint      NOT NULL REFERENCES ch10_b.broadcasts(id),
  user_id      bigint      NOT NULL,
  read_at      timestamptz NOT NULL,
  PRIMARY KEY (broadcast_id, user_id)
);
