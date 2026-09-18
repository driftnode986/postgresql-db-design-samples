-- 案A: 残高の列を持たず、付与ロットの残りを合計して残高とする
--
-- 採取した案（opus）がこの形だった。残高を保存する場所が 1 か所しか無いので、
-- 「残高の列」と「取引の合計」が食い違うことが原理的に起きない。
--
-- 残高 = SUM(remaining) WHERE remaining > 0 AND expires_at > now()
--
-- 期限切れは、問い合わせの WHERE で落ちるので、失効のバッチを回さなくても残高は正しい。
CREATE SCHEMA ch07_a;

-- 付与 1 回 = 1 行。granted は付与時の額（変えない）、remaining は現在の残り
CREATE TABLE ch07_a.point_lots (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  granted    bigint      NOT NULL CHECK (granted > 0),
  remaining  bigint      NOT NULL CHECK (remaining >= 0),
  expires_at timestamptz NOT NULL,
  granted_at timestamptz NOT NULL,
  CONSTRAINT point_lots_remaining_le_granted CHECK (remaining <= granted)
);

-- 残高の合計にも、期限の近い順の消し込みにも、この 1 本が効く。
-- 🔴 fefo = First-Expire-First-Out（期限が近い順）。
--    fifo（付与の古い順）ではない。付与順に使うと、期限の近いポイントが失効する
CREATE INDEX point_lots_fefo
  ON ch07_a.point_lots (user_id, expires_at, id)
  WHERE remaining > 0;

-- 何がいつ起きたかの台帳。残高の計算には使わない（説明のために残す）
CREATE TABLE ch07_a.point_txns (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  kind       text        NOT NULL CHECK (kind IN ('grant', 'use')),
  amount     bigint      NOT NULL CHECK (amount > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX point_txns_user ON ch07_a.point_txns (user_id, id);

-- どの利用が、どのロットからいくら引いたか。「なぜこの残高か」を復元できる
CREATE TABLE ch07_a.lot_consumptions (
  txn_id bigint NOT NULL REFERENCES ch07_a.point_txns(id),
  lot_id bigint NOT NULL REFERENCES ch07_a.point_lots(id),
  taken  bigint NOT NULL CHECK (taken > 0),
  PRIMARY KEY (txn_id, lot_id)
);

GRANT SELECT, INSERT, UPDATE
  ON ch07_a.point_lots, ch07_a.point_txns, ch07_a.lot_consumptions TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch07_a TO book_app;
