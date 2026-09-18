-- 4 案に同じ取引を入れるための元データ。
-- 元データを 1 回だけ作り、各案の load.sql が ORDER BY id で写す。
-- 案ごとに別々に生成すると、乱数が違って案の比較にならない。
CREATE SCHEMA IF NOT EXISTS ch07_r;

DROP TABLE IF EXISTS ch07_r.src_txn;
DROP TABLE IF EXISTS ch07_r.src_user;

CREATE TABLE ch07_r.src_user (
  id   bigint PRIMARY KEY,
  name text   NOT NULL
);

-- 付与と利用の履歴。kind は 'grant'（付与）か 'use'（利用）。
-- amount は常に正で、符号は kind で決まる（採取した 3 本のうち 2 本がこの形だった）。
--
-- expires_at は付与のときだけ入る。利用のときは NULL。
-- 🔴 期限は付与日と連動していない。付与が古いほど期限が近いとは限らない
--    （キャンペーンで配った短期のポイントは、あとから付与されて先に切れる）。
--    この食い違いがあるので、消し込みの順序を「付与の古い順」にすると事故になる。
CREATE TABLE ch07_r.src_txn (
  id         bigint      PRIMARY KEY,
  user_id    bigint      NOT NULL,
  kind       text        NOT NULL CHECK (kind IN ('grant', 'use')),
  amount     bigint      NOT NULL CHECK (amount > 0),
  expires_at timestamptz,
  created_at timestamptz NOT NULL,
  CHECK ((kind = 'grant') = (expires_at IS NOT NULL))
);
