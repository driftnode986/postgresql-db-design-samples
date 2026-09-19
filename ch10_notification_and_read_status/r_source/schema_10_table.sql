-- 第10章の元データ。3 案はここから同じ中身を写す。
--
-- 🔴 案ごとにデータを作り直すと、案の違いではなく乱数の違いを測ることになる。
--    元データを 1 回だけ作り、各案の load.sql が ORDER BY id で写す。
--
-- 元データが持つのは「誰に・いつ・どの種類の通知が届き、いつ読まれたか」だけである。
-- それを受信者ごとの行にするか（案A）、告知を 1 行に畳むか（案B）、
-- カーソルを持つか（案C）は、各案の load.sql が決める。

CREATE SCHEMA IF NOT EXISTS ch10_r;

DROP TABLE IF EXISTS ch10_r.src_delivery;
DROP TABLE IF EXISTS ch10_r.src_notice;
DROP TABLE IF EXISTS ch10_r.src_user;

-- 利用者
CREATE TABLE ch10_r.src_user (
  id        bigint PRIMARY KEY,
  login     text   NOT NULL,
  -- 未読をためこむ利用者か（偏りを作るための印。第10章の測定の前提）
  is_hoarder boolean NOT NULL
);

-- 通知の中身。個別の通知（addressee_id が非 NULL）と
-- 全員向けの告知（addressee_id が NULL）の両方を持つ。
CREATE TABLE ch10_r.src_notice (
  id           bigint PRIMARY KEY,
  kind         text   NOT NULL,
  is_broadcast boolean NOT NULL,
  addressee_id bigint,                      -- 個別のときだけ非 NULL
  body         text   NOT NULL,
  created_at   timestamptz NOT NULL,
  -- 🔴 個別の通知には宛先があり、告知には無い。元データの時点で保証する
  CONSTRAINT src_notice_addressee CHECK (is_broadcast = (addressee_id IS NULL))
);

-- 「誰がその通知をいつ読んだか」。読んでいないものは行が無い。
-- 案A はこれを notifications.read_at に写し、案B は別表に写し、
-- 案C はこれを畳んでカーソルにする。
CREATE TABLE ch10_r.src_delivery (
  notice_id bigint NOT NULL REFERENCES ch10_r.src_notice(id),
  user_id   bigint NOT NULL REFERENCES ch10_r.src_user(id),
  read_at   timestamptz,                    -- NULL = 未読
  PRIMARY KEY (notice_id, user_id)
);

CREATE INDEX src_delivery_user ON ch10_r.src_delivery (user_id);
