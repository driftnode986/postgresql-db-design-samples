-- 案D: 台帳 + 期間ごとの締め残高
--
-- 残高 = 最新の締め残高 + それ以降の取引の合計。
-- 案C（全件の合計）の読む行数を、締めの時点から先だけに減らす。
--
-- 案C と違うのは締め残高の表があることだけで、台帳の構造は同じ。
-- 締めの行は追記するだけで、過去の締め残高は書き換えない。
-- そのため「過去の時点の残高はいくらだったか」を、あとから問われても答えられる。
CREATE SCHEMA ch07_d;

CREATE TABLE ch07_d.point_txns (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  kind       text        NOT NULL CHECK (kind IN ('grant', 'use')),
  amount     bigint      NOT NULL CHECK (amount > 0),
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX point_txns_user ON ch07_d.point_txns (user_id, id);

-- 締め残高。「この取引 id までを合計すると、残高はこの値」を記録する。
-- 🔴 時刻ではなく取引の id で区切る。時刻で区切ると、締めたあとに
--    created_at がそれより前の取引が入ってきたとき、二重に数えてしまう
CREATE TABLE ch07_d.point_snapshots (
  user_id     bigint      NOT NULL,
  as_of_txn_id bigint     NOT NULL,
  balance     bigint      NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, as_of_txn_id)
);

GRANT SELECT, INSERT, UPDATE ON ch07_d.point_txns, ch07_d.point_snapshots TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch07_d TO book_app;
