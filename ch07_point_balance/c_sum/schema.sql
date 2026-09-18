-- 案C: 台帳だけを持ち、残高は取引の合計で求める
--
-- 🔴 この案は、要件を渡して設計を書かせた 3 本のどれからも出なかった（ch07_first_idea.md）。
--    有効期限という要件があると、期限ごとの残りを持つ表が避けられないためである。
--    本書では「取引が増えると照会がどうなるか」を見るための対照として置く。
--    第5章の f_naive と同じ扱いで、採取された案ではない。
--
-- 残高 = SUM(付与) - SUM(利用)。保存する場所が 1 つも無いので、食い違いは原理的に起きない。
CREATE SCHEMA ch07_c;

CREATE TABLE ch07_c.point_txns (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  kind       text        NOT NULL CHECK (kind IN ('grant', 'use')),
  amount     bigint      NOT NULL CHECK (amount > 0),
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 会員ごとの取引を引くための索引。残高の合計はこれを辿る
CREATE INDEX point_txns_user ON ch07_c.point_txns (user_id, id);

GRANT SELECT, INSERT, UPDATE ON ch07_c.point_txns TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch07_c TO book_app;
