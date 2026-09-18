-- 案B: 残高の列を持ち、ロットと台帳も持つ
--
-- 採取した 3 本のうち 2 本（sonnet / haiku）がこの形だった。最多数派である。
-- 残高は 1 行を読むだけなので、取引が何件あっても照会は一定の速さになる。
--
-- 🔴 そのかわり、残高を置く場所が 2 か所になる（balance の列と、ロットの残りの合計）。
--    この 2 つが食い違わないことは、DDL では保証できない。書き込みの手順で守る
CREATE SCHEMA ch07_b;

-- 会員ごとに 1 行。マイページはこの 1 行を読む
CREATE TABLE ch07_b.point_balances (
  user_id    bigint PRIMARY KEY,
  balance    bigint      NOT NULL DEFAULT 0 CHECK (balance >= 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ch07_b.point_lots (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  granted    bigint      NOT NULL CHECK (granted > 0),
  remaining  bigint      NOT NULL CHECK (remaining >= 0),
  expires_at timestamptz NOT NULL,
  granted_at timestamptz NOT NULL,
  CONSTRAINT point_lots_remaining_le_granted CHECK (remaining <= granted)
);

CREATE INDEX point_lots_fefo
  ON ch07_b.point_lots (user_id, expires_at, id)
  WHERE remaining > 0;

-- 台帳。案A と違い、その取引の直後の残高も記録する（18 の RETURNING old/new で 1 文で取れる）
CREATE TABLE ch07_b.point_txns (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id        bigint      NOT NULL,
  kind           text        NOT NULL CHECK (kind IN ('grant', 'use')),
  amount         bigint      NOT NULL CHECK (amount > 0),
  balance_before bigint,
  balance_after  bigint,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX point_txns_user ON ch07_b.point_txns (user_id, id);

CREATE TABLE ch07_b.lot_consumptions (
  txn_id bigint NOT NULL REFERENCES ch07_b.point_txns(id),
  lot_id bigint NOT NULL REFERENCES ch07_b.point_lots(id),
  taken  bigint NOT NULL CHECK (taken > 0),
  PRIMARY KEY (txn_id, lot_id)
);

GRANT SELECT, INSERT, UPDATE ON ch07_b.point_balances, ch07_b.point_lots,
                                ch07_b.point_txns, ch07_b.lot_consumptions TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch07_b TO book_app;
