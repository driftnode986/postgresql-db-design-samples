-- 案C: 利用者ごとに「ここまで読んだ」位置を持つ
--
-- 告知は 1 行だけ持ち（案B と同じ）、既読は「どの告知まで読んだか」という
-- 位置（カーソル）を利用者 1 人につき 1 つだけ持つ。
-- 「この告知だけ既読」はできなくなるが、既読にする操作が 1 行の更新で済む。
--
-- 利点: 「すべて既読にする」が 1 行の更新で終わる。表の大きさが利用者数で決まる。
-- 代償: 既読の粒度を失う。飛ばして読むことができない。

CREATE SCHEMA IF NOT EXISTS ch10_c;

DROP TABLE IF EXISTS ch10_c.read_cursors;
DROP TABLE IF EXISTS ch10_c.broadcasts;
DROP TABLE IF EXISTS ch10_c.notifications;

-- 個別の通知（案A・案B と同じ形）
CREATE TABLE ch10_c.notifications (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  kind       text        NOT NULL,
  body       text        NOT NULL,
  read_at    timestamptz,
  created_at timestamptz NOT NULL
);

-- 全員向けの告知（案B と同じ。id は元データのものを使う）
CREATE TABLE ch10_c.broadcasts (
  id         bigint      PRIMARY KEY,
  kind       text        NOT NULL,
  body       text        NOT NULL,
  created_at timestamptz NOT NULL
);

-- 利用者ごとに 1 行。「この id までの告知は読んだ」という位置を持つ。
--
-- 🔴 位置を id で持てるのは、告知の id が時刻順に増えるからである。
--    id が時刻順でない設計（UUIDv4 など）では、この案は成立しない。
CREATE TABLE ch10_c.read_cursors (
  user_id             bigint PRIMARY KEY,
  broadcast_read_upto bigint NOT NULL DEFAULT 0,
  updated_at          timestamptz NOT NULL DEFAULT now()
);
